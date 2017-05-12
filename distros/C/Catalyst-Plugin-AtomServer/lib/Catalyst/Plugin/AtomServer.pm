# $Id: AtomServer.pm 1257 2006-06-27 17:07:05Z btrott $

package Catalyst::Plugin::AtomServer;
use strict;

our $VERSION = '0.04';

## todo:
## dispatching based on request method?

use Catalyst::Request;
use NEXT;
use XML::Atom;

{
    package Catalyst::Request;
    __PACKAGE__->mk_accessors(qw( url_parameters is_atom is_soap
                                  _body_parsed ));

    sub body_parsed {
        my $req = shift;
        unless ($req->_body_parsed) {
            my $doc;
            if (XML::Atom->LIBXML) {
                my $parser = XML::LibXML->new;
                $doc = $parser->parse_file($req->body);
            } else {
                $doc = XML::XPath->new(filename => $req->body);
            }
            $req->_body_parsed($doc);
        }
        $req->_body_parsed;
    }
}

sub prepare {
    my $class = shift;
    my $c = $class->NEXT::prepare(@_);
    my $req = $c->request;

    ## Extract parameters from URI path info.
    my $param = {};
    for my $pair (@{ $req->arguments }) {
        my($k, $v) = split /=/, $pair, 2;
        $param->{$k} = $v;
    }
    $req->url_parameters($param);

    ## If the request has a SOAP wrapper, unwrap it.
    if (my $action = $req->header('SOAPAction')) {
        $req->is_soap(1);
        $action =~ s/"//g;
        my($method) = $action =~ /\/([^\/]+)$/;
        $req->method($method);
    }

    $c;
}

sub finalize {
    my $c = shift;
    unless ($c->request->is_atom) {
        return $c->NEXT::finalize(@_);
    }
    my $res = $c->response;
    if ($c->request->is_soap && (my $body = $res->body)) {
        $body =~ s/^(<\?xml.*?\?>)//;
        $body = <<SOAP;
$1
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>$body</soap:Body>
</soap:Envelope>
SOAP
        $res->body($body);
    }
    $c->NEXT::finalize(@_);
}

sub finalize_error {
    my $c = shift;
    unless ($c->request->is_atom) {
        return $c->NEXT::finalize_error(@_);
    }
    if (defined(my $err = $c->error->[0])) {
        my $res = $c->response;
        my $status = $res->status;
        if ($c->request->is_soap || !$status || $status == 200) {
            $res->status(500);
            $status = $res->status;
        }
        my $body = UNIVERSAL::can($err, 'message') ? $err->message : $err;
        if ($c->request->is_soap) {
            $res->body(<<FAULT);
<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <soap:Fault>
      <faultcode>$status</faultcode>
      <faultstring>$body</faultstring>
    </soap:Fault>
  </soap:Body>
</soap:Envelope>
FAULT
        } else {
            $res->body(<<XML);
<?xml version="1.0" encoding="utf-8"?>
<error>$body</error>
XML
        }
    }
}

1;
__END__

=head1 NAME

Catalyst::Plugin::AtomServer - Atom API server for Catalyst applications

=head1 SYNOPSIS

    use Catalyst qw( AtomServer
                     Authentication
                     Authentication::Credential::Atom
                     Authentication::Store::Minimal
                   );

=head1 DESCRIPTION

I<Catalyst::Plugin::AtomServer> implements the necessary bits to make it easy
to build an Atom API server for any Catalyst-based application.

It implements:

=over 4

=item * Simple XML Views

I<Catalyst::View::Atom::XML> provides a base view class that your application
can subclass can use to provide a simple view. Given an I<XML::Atom>-based
class in C<$c-E<lt>stash-E<gt>{xml_atom_object}>, it will automatically
serialize the object to XML and set the appropriate response headers.

=item * Request Extensions

I<Catalyst::Plugin::AtomServer> extends the I<Catalyst::Request> object to
add a couple of useful methods:

=over 4

=item * $req->is_atom

Once you know that a particular request is an Atom request, your Catalyst
handler should set I<is_atom> to C<1>, like so:

    $c->request->is_atom(1);

=item * $req->url_parameters

Atom servers often implement parametrized requests in the I<path_info>
portion of the request URI. These parameters will be automatically split up
into the I<url_parameters> hash reference. For example, the URI

    /base/foo=bar/baz=quux/

would be split into the hash reference

    {
        foo => 'bar',
        baz => 'quux',
    }

=item * $req->body_parsed

A parsed XML document containing the Atom portion of the request (the entire
request content in the case of a REST request, and only the Atom portion of
a SOAP request).

You can pass this in directly to initialize an I<XML::Atom>-based object.
For example:

    my $entry = XML::Atom::Entry->new( Doc => $req->body_parsed );

=back

=item * Authentication

I<Catalyst::Plugin::Authentication::Credential::Atom> provides support for
Basic and WSSE authentication using an Atom envelope. WSSE is supported
using either SOAP or REST, and Basic is supported in REST only.

=item * REST and SOAP interfaces

The Atom API supports either a REST interface or a SOAP interface using
a document-literal SOAP envelope. I<Catalyst::Plugin::AtomServer> supports
both interfaces, transparently for your application.

=item * Error Handling

I<Catalyst::Plugin::AtomServer> will automatically catch any exceptions
thrown by your application, and it will wrap the exception in the proper
response expected by an Atom client.

=back

=head1 EXAMPLE

Below is an example server that implements authentication, dispatching,
and views.

    package My::App;
    use strict;

    use Catalyst qw( AtomServer
                     Authentication
                     Authentication::Credential::Atom
                     Authentication::Store::Minimal
                   );
    use My::App::View::XML;
    use XML::Atom::Feed;

    __PACKAGE__->config(
        name => 'MyApp',
        authentication => { users => { foo => { password => 'bar' } } },
    );

    __PACKAGE__->setup;

    sub default : Private {
        my($self, $c) = @_;
        $c->request->is_atom(1);
        my $method = $c->request->method;
        if ($method eq 'GET') {
            $c->forward('get_entries');
        }
    }

    sub get_entries : Private {
        my($self, $c) = @_;

        ## Authenticate the user using WSSE or Basic auth.
        $c->login_atom or die "Unauthenticated";

        my $feed = XML::Atom::Feed->new;
        $feed->title('Blog');
        $c->stash->{xml_atom_object} = $feed;
    }

    sub end : Private {
        my($self, $c) = @_;
        $c->forward('My::App::View::XML');
    }

    package My::App::View::XML;
    use base qw( Catalyst::View::Atom::XML );

=head1 SEE ALSO

L<XML::Atom>, L<Catalyst>

=head1 AUTHOR

Six Apart, cpan@sixapart.com

=head1 LICENSE

I<Catalyst::Plugin::AtomServer> is free software; you may redistribute it
and/or modify it under the same terms as Perl itself.

=head1 AUTHOR & COPYRIGHT

Except where otherwise noted, I<Catalyst::Plugin::AtomServer> is
Copyright 2006 Six Apart, cpan@sixapart.com. All rights reserved.

=cut
