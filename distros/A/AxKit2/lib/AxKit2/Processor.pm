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

# A "Processor" is responsible for controlling XML transformations

package AxKit2::Processor;

use strict;
use warnings;

use Exporter ();

our @ISA = qw(Exporter);
our @EXPORT = qw(XSP XSLT TAL XPathScript);

use XML::LibXML;
use AxKit2::Transformer::XSP;
use AxKit2::Utils qw(bytelength);

our $parser = XML::LibXML->new();

# ->new($path [, $input]);
sub new {
    my $class = shift; $class = ref($class) if ref($class);
    my $client = shift || die "A processor needs a client";
    my $path  = shift || die "A processor needs source document path";
    
    my $self = bless {client => $client, path => $path}, $class;
    
    @_ and $self->{input}  = shift;
    @_ and $self->{output} = shift;
    
    return $self;
}

sub path {
    my $self = shift;
    $self->{path};
}

sub input {
    my $self = shift;
    $self->{input};
}

sub client {
    my $self = shift;
    $self->{client};
}

sub dom {
    my $self = shift;
    @_ and $self->{input} = shift;
    
    my $input =    $self->{input} 
                || do { open(my $fh, $self->{path})
                     || die "open($self->{path}): $!";
                        die "open($self->{path}): directory" if -d $fh;
                        $fh };
    
    if (ref($input) eq 'XML::LibXML::Document') {
        return $input;
    }
    elsif (ref($input) eq 'GLOB') {
        # parse $fh
        return $self->{input} = $parser->parse_fh($input);
    }
    else {
        # assume string
        return $self->{input} = $parser->parse_string($input);
    }
}

sub output {
    my $self   = shift;
    my $client = $self->{client};
    
    if ($self->{output}) {
        $self->{output}->($client, $self->dom);
    }
    else {
        my $out = $self->dom->toString;
        $client->headers_out->header('Content-Length', bytelength($out));
        $client->headers_out->header('Content-Type', 'text/xml');
        $client->send_http_headers;
        $client->write($out);
    }
}

sub str_to_transform {
    my $str = shift;
    ref($str) and return $str;
    if ($str =~ /^(TAL|XSP|XSLT)\((.*)\)/) {
        return $1->($2);
    }
    else {
        die "Unknown transform type: $str";
    }
}

sub transform {
    my $self = shift;
    my @transforms = map { str_to_transform($_) } @_;
    
    my $pos = 0;
    my ($dom, $outfunc);
    for my $trans (@transforms) {
        $trans->client($self->client);
        if ($AxKit2::Processor::DumpIntermediate) {
            mkdir("/tmp/axtrace");
            open(my $fh, ">/tmp/axtrace/trace.$pos");
            print $fh ($dom || $self->dom)->toString;
        }
        ($dom, $outfunc) = $trans->transform($pos++, $self);
        # $trans->client(undef);
        $self->dom($dom);
    }
    
    return $self->new($self->client, $self->path, $dom, $outfunc);
}

# Exported transformer functions. These are really just short cuts for 
# calling the transformer constructors.

sub XSP {
    die "XSP takes no arguments" if @_;
    return AxKit2::Transformer::XSP->new();
}

sub XSLT {
    my $stylesheet = shift || die "XSLT requires a stylesheet";
    require AxKit2::Transformer::XSLT;
    return AxKit2::Transformer::XSLT->new($stylesheet, @_);
}

sub TAL {
    my $stylesheet = shift || die "TAL requires a stylesheet";
    require AxKit2::Transformer::TAL;
    return AxKit2::Transformer::TAL->new($stylesheet, @_);
}

sub XPathScript {
    my $stylesheet = shift || die "XPathScript requires a stylesheet";
    require AxKit2::Transformer::XPathScript;
    my $output_style = shift;
    return AxKit2::Transformer::XPathScript->new($stylesheet, $output_style);
}

1;

__END__

=head1 NAME

AxKit2::Processor - AxKit's core XML processing engine

=head1 DESCRIPTION

The C<Processor> is provided to the C<xmlresponse> hook in order to facilitate
transforming XML prior to being output to the browser. A typical XSLT example
might look like this:

  sub hook_xmlresponse {
    my ($self, $input) = @_;
    
    # $input is a AxKit2::Processor object
    
    my $stylesheet = './myfirstplugin/stylesheets/default.xsl';
    my $out = $input->transform(XSLT($stylesheet));
    
    # $out is also an AxKit2::Processor object
    
    return OK, $out;
  }

=head1 API

=head2 C<< CLASS->new( CLIENT, PATH [, INPUT [, OUTPUT]] ) >>

Normally you would not need to call the constructor - this is done for you.

=head2 C<< $obj->path >>

Returns the path to the object being requested. Normally the same as the
request filename.

=head2 C<< $obj->input >>

This method returns the input DOM if there was one. This may be useful for
a transformer to know - for example XSP will need to recompile its code if
there was an input DOM because it implies XSP -> XSP.

Normally you would just access the input DOM via C<< $obj->dom >>.

=head2 C<< $obj->client >>

The C<AxKit2::Connection> object for this request.

=head2 C<< $obj->dom( [ INPUT ] ) >>

Get/set the DOM for whatever is being transformed. Auto-generates a DOM if there
wasn't one already stored in the I<input>.

See L<XML::LibXML::Document> for the DOM API.

=head2 C<< $obj->output() >>

Sends the transformation result to the browser. You do not need to call this as
it is performed by AxKit when you return (C<OK>, PROCESSOR) from your xmlresponse
hook.

=head2 C<< $obj->transform( LIST ) >>

Performs the transformations specified in C<LIST>. The transform method is
extremely flexible in how it will accept this list of transformations.

The following are all equivalent:

=over 4

=item * As strings:

  $input->transform(qw(
            XSP
            XSLT(/path/to/stylesheet.xsl)
            XSLT(/path/to/xml2html.xsl)
            ));

=item * Via helper functions:

  $input->transform(
        XSP()
     => XSLT("/path/to/stylesheet.xsl")
     => XSLT("/path/to/xml2html.xsl")
     );

=item * By constructing transformers directly:

  $input->transform(
        AxKit2::Transformer::XSP->new(),
        AxKit2::Transformer::XSLT->new("/path/to/stylesheet.xsl"),
        AxKit2::Transformer::XSLT->new("/path/to/xml2html.xsl"),
    );

=back

Note that C<XSLT()> can take a list of key/value pairs to pass to the stylesheet
as parameters. Unlike AxKit1 the stylesheet does NOT automatically get access to
all the querystring parameters - you have to explicitly pass these in.

=cut
