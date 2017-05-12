# Copyright 2001-2006 The Apache Software Foundation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

package AxKit2::Transformer::TAL;

use strict;
use warnings;

use base qw(AxKit2::Transformer::XSLT);

use AxKit2::Utils qw(bytelength);

my $parser  = XML::LibXML->new();
my $xslt    = XML::LibXSLT->new();
my $data    = do { local $/; <DATA> };

my %cache;
sub transform {
    my $self = shift;
    my ($pos, $processor) = @_;
    
    my $dom = $processor->dom;
    
    my $stylefile = $self->{stylesheet};
    
    my $stylesheet = $cache{$stylefile};
    if (!$stylesheet) {
        my $style_doc = $parser->parse_file($stylefile);
        my $xslparams = $self->mk_params();
        my $tal_style = $data;
        $tal_style    =~ s/!TALPARAMS!/$xslparams/;
        # print "Parsing: $tal_style\n";
        my $tal2xsl   = $xslt->parse_stylesheet($parser->parse_string($tal_style));
        my $xslt_dom  = $tal2xsl->transform($style_doc);
        $stylesheet   = $xslt->parse_stylesheet($xslt_dom);
        
        $cache{$stylefile} = $stylesheet;
    }
    
    my $results = $stylesheet->transform($dom, AxKit2::Transformer::XSLT::fixup_params(@{ $self->{params} }));
    
    return $results, sub { $self->output(@_) };
}

sub mk_params {
    my $self = shift;
    my %params = @{$self->{params}};
    my $output = '';
    for (keys %params) {
        $output .= "<xsl:param name='$_'/>\n";
    }
    return $output;
}

sub output {
    my ($self, $client, $dom) = @_;
    
    my ($out, $ct);
    if (lc($dom->documentElement->nodeName) eq 'html') {
        $out = $dom->toStringHTML();
        $ct  = "text/html";
    }
    else {
        $out = $dom->toStringHTML();
        $ct  = "application/xml";
    }
    my $enc = "UTF-8";
    
    $client->headers_out->header('Content-Length', bytelength($out));
    $client->headers_out->header('Content-Type', "$ct; charset=$enc");
    $client->send_http_headers;
    $client->write($out);
}

1;

__DATA__
<?xml version="1.0"?>

<!--
  Copyright 2004-2005 Bitflux GmbH

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
  
  $Id: popoon.php 4323 2005-05-25 17:45:38Z chregu 

-->

<xsl:stylesheet version="1.0"  
    xmlns:metal="http://xml.zope.org/namespaces/metal" 
    xmlns:bxf="http://bitflux.org/functions" 
    xmlns:tal="http://xml.zope.org/namespaces/tal" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xmlns:xslout="whatever" 
    xmlns:func="http://exslt.org/functions" 
    extension-element-prefixes="func">

    <xsl:namespace-alias stylesheet-prefix="xslout" result-prefix="xsl"/>
    <func:function name="bxf:tales">
        <xsl:param name="path"/>
        <xsl:choose>
            <xsl:when test="$path = ''">
                <func:result select="'node()'"/>
            </xsl:when>
            <xsl:otherwise>
                <func:result select="$path"/>
            </xsl:otherwise>
        </xsl:choose>
    </func:function>
    <xsl:template match="/">
        <xslout:stylesheet version="1.0" exclude-result-prefixes="bxf tal metal">
            <xsl:choose>
              <xsl:when test="local-name(/node()) = 'html'">
                <xslout:output encoding="utf-8" method="xml" doctype-public="-//W3C//DTD XHTML 1.0 Transitional//EN" doctype-system="http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"/>
              </xsl:when>
              <xsl:otherwise>
                <xslout:output encoding="utf-8" method="xml"/>
              </xsl:otherwise>
            </xsl:choose>
            !TALPARAMS!
            <xsl:apply-templates select="//*[@tal:include]" mode="init"/>
            <xsl:apply-templates select="//*[@tal:match]" mode="init"/>
            <xsl:apply-templates select="//*[@metal:use-macro]" mode="init"/>
            <xslout:template match="/">

                <xsl:apply-templates/>
            </xslout:template>
            <!--copy all elements -->
            <xslout:template match="*">
                <xslout:copy>
                    <xslout:apply-templates select="@*"/>
                    <xslout:apply-templates/>
                </xslout:copy>
            </xslout:template>
               <!-- copy all attributes -->
            <xslout:template match="@*">
                <xslout:copy-of select="."/>
            </xslout:template>
        </xslout:stylesheet>

    </xsl:template>


    <xsl:template match="*[@tal:condition]" priority="10">
        <xslout:if test="{bxf:tales(@tal:condition)}">
            <xsl:apply-templates/>
        </xslout:if>
    </xsl:template>

    <xsl:template match="*[@metal:use-macro]">
        <xsl:variable name="doc" select="substring-before(@metal:use-macro,'#')"/>
        <xsl:variable name="path" select="substring-after(@metal:use-macro,'#')"/>
        <xsl:apply-templates select="document($doc)//*[@metal:define-macro = $path]"/>
     </xsl:template>
     
     <xsl:template match="*[@metal:use-macro]" mode="init">
        <xsl:variable name="doc" select="substring-before(@metal:use-macro,'#')"/>
        <xsl:variable name="path" select="substring-after(@metal:use-macro,'#')"/>
        <xsl:apply-templates select="document($doc)//*[@metal:define-macro = $path]" mode="init"/>
     </xsl:template>
     
     <xsl:template match="text()" mode ="init">
        <xsl:if test="ancestor::*[@tal:match]">
            <xsl:copy/>
        </xsl:if>
     </xsl:template>
     
     
    
    <xsl:template match="@metal:define-macro">
    </xsl:template>
    <xsl:template match="*[@tal:content]" name="tal_content">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:call-template name="copy-value-apply">
                <xsl:with-param name="path" select="@tal:content"/>
            </xsl:call-template>
        </xsl:copy>
    </xsl:template>


    <xsl:template match="*[@tal:replace]">
        <xsl:call-template name="copy-value-apply">
            <xsl:with-param name="path" select="@tal:replace"/>
        </xsl:call-template>
    </xsl:template>


    <xsl:template match="*[@tal:repeat]">
        <xsl:variable name="v" select="substring-before(@tal:repeat,' ')"/>
        <xsl:variable name="x" select="substring-after(@tal:repeat,' ')"/>
        <xslout:for-each select="{bxf:tales($x)}">
            <xslout:variable name="{$v}" select="."/>
            <xsl:copy>
                <xsl:apply-templates select="@*"/>
                <xsl:apply-templates/>
            </xsl:copy>
        </xslout:for-each>
    </xsl:template>

    <!-- special case of above if tal:repeat and tal:content are in the same element -->
    <xsl:template match="*[@tal:repeat and @tal:content]">
        <xsl:variable name="v" select="substring-before(@tal:repeat,' ')"/>
        <xsl:variable name="x" select="substring-after(@tal:repeat,' ')"/>
        <xslout:for-each select="{bxf:tales($x)}">
            <xslout:variable name="{$v}" select="."/>
            <xsl:call-template name="tal_content"/>
        </xslout:for-each>
    </xsl:template>
    
      
    <xsl:template match="@*">
        <xsl:if test="namespace-uri() != 'http://xml.zope.org/namespaces/tal'">
            <xsl:copy-of select="."/>
        </xsl:if>
    </xsl:template>

    <xsl:template match="*[@tal:match]"/>

    <xsl:template match="*[@tal:include]" mode="init">
        <xsl:call-template name="talIncludes">
            <xsl:with-param name="include" select="@tal:include"/>
        </xsl:call-template>
    </xsl:template>

    <xsl:template name="talIncludes">
        <xsl:param name="include"/>
        <xsl:choose>
            <xsl:when test="contains($include,' ')">
                <xslout:include href="{substring-before($include,' ')}"/>
                <xsl:call-template name="talIncludes">
                    <xsl:with-param name="include" select="substring-after($include,' ')"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xslout:include href="{$include}"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="*[@tal:match]" mode="init">
        <xslout:template match="{@tal:match}">
            <xsl:apply-templates/>
        </xslout:template>
    </xsl:template>
    

      <!-- outputs value-of, copy-of our apply-templates of $path depending on the first param
              "/foo/bar" ->             <xsl:value-of select="/foo/bar"/> 
              "text /foo/bar" ->        <xsl:value-of select="/foo/bar"/>
              "structure /foo/bar" ->   <xsl:copy-of select="/foo/bar"/>
         -->
    <xsl:template name="copy-value-apply">
        <xsl:param name="path"/>
        <xsl:variable name="mode">
            <xsl:value-of select="substring-before($path,' ')"/>
        </xsl:variable>
        <xsl:variable name="spath">
            <xsl:value-of select="substring-after($path,' ')"/>
        </xsl:variable>

        <xsl:choose>
           <!-- if no mode, use value-of -->
           <xsl:when test="$path ='structure'">
                <xslout:apply-templates select="{bxf:tales('')}"/>
           </xsl:when>
            <xsl:when test="$mode = ''">
                <xslout:value-of select="{bxf:tales($path)}"/>
            </xsl:when>
            <xsl:when test="$mode = 'text'">
                <xslout:value-of select="{bxf:tales($spath)}"/>
            </xsl:when>
            <xsl:when test="$mode = 'text-escaped'">
                <xslout:value-of select="{bxf:tales($spath)}" disable-output-escaping="yes"/>
            </xsl:when>
            <xsl:when test="$path = 'structure .'">
                <xslout:copy>
                    <xslout:apply-templates select="@*"/>
                    <xslout:apply-templates select="{bxf:tales('')}"/>
                </xslout:copy>
            </xsl:when>
            <xsl:when test="$mode = 'structure'">
                <xslout:apply-templates select="{bxf:tales($spath)}"/>
            </xsl:when>
        </xsl:choose>
    </xsl:template>


    <xsl:template match="@tal:attributes">
        <xsl:call-template name="talAttribute">
            <xsl:with-param name="attr" select="."/>
        </xsl:call-template>
    </xsl:template>

    <xsl:template name="talAttribute">
        <xsl:param name="attr"/>
        <xsl:choose>
            <xsl:when test="contains($attr,'; ')">

                <xsl:call-template name="talAttribute">
                    <xsl:with-param name="attr" select="substring-after($attr,'; ')"/>
                </xsl:call-template>
                <xsl:call-template name="outputTalAttribute">
                    <xsl:with-param name="attr" select="substring-before($attr,'; ')"/>
                </xsl:call-template>
            </xsl:when>

            <xsl:otherwise>
                <xsl:call-template name="outputTalAttribute">
                    <xsl:with-param name="attr" select="$attr"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="outputTalAttribute">
        <xsl:param name="attr"/>
        <xsl:variable name="name" select="substring-before($attr,' ')"/>
        <xsl:variable name="value" select="substring-after($attr,' ')"/>
        <xslout:attribute name="{$name}">
            <xslout:value-of select="{bxf:tales($value)}"/>
        </xslout:attribute>

    </xsl:template>

    <xsl:template match="*">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:apply-templates/>
        </xsl:copy>
    </xsl:template>
    
        
    <xsl:template match="comment()">
            <xslout:comment>
                <xsl:value-of select="."/>
            </xslout:comment>
     </xsl:template>    
     
         
    <xsl:template match="processing-instruction()">
            <xslout:processing-instruction name="{name()}">
                <xsl:value-of select="."/>
            </xslout:processing-instruction>
     </xsl:template>    
</xsl:stylesheet>
