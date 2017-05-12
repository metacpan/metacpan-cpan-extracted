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

package AxKit2::Transformer::XSLT;

use strict;
use warnings;

use base qw(AxKit2::Transformer);

use XML::LibXML;
use XML::LibXSLT;
use AxKit2::Constants;
use AxKit2::Utils qw(bytelength);

my $parser = XML::LibXML->new();
my $xslt = XML::LibXSLT->new();

sub new {
    my $class = shift;
    my $stylesheet = shift;
    
    my @params = @_;
    
    return bless { stylesheet => $stylesheet, params => \@params }, $class;
}

my %cache;
sub transform {
    my $self = shift;
    my ($pos, $processor) = @_;
    
    my $dom = $processor->dom;

    my $stylefile = $self->{stylesheet};
    
    $self->log(LOGINFO, "Transformer::XSLT($stylefile) running");
    
    my $stylesheet = $cache{$stylefile};
    if (!$stylesheet) {
        my $style_doc = $parser->parse_file($stylefile);
        
        $stylesheet = $xslt->parse_stylesheet($style_doc);
        $cache{$stylefile} = $stylesheet;
    }
    
    my $results = $stylesheet->transform($dom, fixup_params(@{ $self->{params} }));
    
    return $results, sub { $self->output(@_) };
}

sub fixup_params {
    my @results;
    while (@_) {
        push @results, XML::LibXSLT::xpath_to_string(
                splice(@_, 0, 2)
                );
    }
    return @results;
}

sub output {
    my ($self, $client, $dom) = @_;
    
    my $stylesheet = $cache{$self->{stylesheet}} || die "Not processed";
    
    my $ct  = $stylesheet->media_type;
    my $enc = $stylesheet->output_encoding;
    my $out = $stylesheet->output_string($dom);

    $client->headers_out->header('Content-Length', bytelength($out));
    $client->headers_out->header('Content-Type', "$ct; charset=$enc");
    $client->send_http_headers;
    $client->write($out);
}

1;
