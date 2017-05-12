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

package AxKit2::Transformer::XPathScript;

use strict;
use warnings;

use AxKit2::Constants;
use XML::XPathScript;
use AxKit2::Utils qw(bytelength);

use base qw(AxKit2::Transformer);

sub new {
    my $class = shift;
    
    my $stylesheet = shift;
    my $output_style = shift;
    
    return bless { stylesheet => $stylesheet,
                   output_style => $output_style }, $class;
}

sub transform {
    my $self = shift;
    my ($pos, $processor) = @_;

    $self->log( LOGDEBUG, 'in transform' );
    
    my $dom = $processor->dom;

    my $xps = XML::XPathScript->new( stylesheetfile => $self->{stylesheet} );
    my $parser = XML::LibXML->new;
    my $result = $xps->transform( $dom );

    my $out_dom;
    unless ( eval { $out_dom = $parser->parse_string( $result ) } ) {
        $out_dom = $parser->parse_string( 
            '<xpathscript:wrapper '
            .'xmlns:xpathscript="http://babyl.dyndns.org/xpathscript" '
            .'xpathscript:type="cdata">'
            .'<![CDATA[' 
            . $result 
            . ']]></xpathscript:wrapper>' );
    }
    
    return $out_dom, sub { $self->output(@_) };
}

sub output {
    my ($self, $client, $dom) = @_;

    $self->log( LOGDEBUG, 'in output' );

    my $out;
    my $ct = 'text/xml';

    if ( my( $root ) = eval { $dom->findnodes( '/xpathscript:wrapper' ) } ) {
        warn "xpathscript:wrapper";
        $ct = $root->getAttribute( 'type' ) 
            if $root->getAttribute( 'type' );
        if ( $ct eq 'cdata' ) {
            $ct = 'text/plain';
            $out = $root->textContent;
        }
        else {
            $out .= $_->toString for $root->childNodes;
        }
    }
    else {
        warn "pure XML, baby";
        $out = $dom->toStringHTML;
    }

    # XPathScript_OutputStyle trumps all
    $ct = $self->{output_style} if $self->{output_style};

    $client->headers_out->header('Content-Length', bytelength($out));
    $client->headers_out->header( 'Content-Type' => $ct );
    $client->send_http_headers;
    $client->write($out);
}

1;
