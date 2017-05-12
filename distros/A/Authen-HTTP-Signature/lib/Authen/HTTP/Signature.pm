package Authen::HTTP::Signature;

use 5.010;
use strict;
use warnings;

use Moo;
use Scalar::Util qw(blessed);
use Carp qw(confess);

use HTTP::Date qw(time2str);
use Data::Dumper;

=head1 NAME

Authen::HTTP::Signature - Sign and validate HTTP headers

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

Create signatures:

    use 5.010;
    use Authen::HTTP::Signature;
    use File::Slurp qw(read_file);
    use HTTP::Request::Common;

    my $key_string = read_file("/my/priv/key.pem") or die $!;

    my $signer = Authen::HTTP::Signature->new(
        key => $key_string,
        key_id => 'Test',
    );

    my $req = POST('http://example.com/foo?param=value&pet=dog',
            Content_Type => 'application/json',
            Content_MD5 => 'Sd/dVLAcvNLSq16eXua5uQ==',
            Content_Length => 18,
            Content => '{"hello": "world"}'
    );

    my $signed_req = $signer->sign($req);

    # adds then signs the 'Date' header with private key using
    # RSA-SHA256, then adds 'Authorization' header to
    # $req

Validate signatures:

    use 5.010;
    use Authen::HTTP::Signature::Parser;
    use HTTP::Request::Common;
    use File::Slurp qw(read_file);
    use Try::Tiny;

    my $req = POST('http://example.com/foo?param=value&pet=dog',
            Content_Type => 'application/json',
            Content_MD5 => 'Sd/dVLAcvNLSq16eXua5uQ==',
            Content_Length => 18,
            Date => 'Thu, 05 Jan 2012 21:31:40 GMT',
            Authorization => q{Signature keyId="Test",algorithm="rsa-sha256",signature="ATp0r26dbMIxOopqw0OfABDT7CKMIoENumuruOtarj8n/97Q3htHFYpH8yOSQk3Z5zh8UxUym6FYTb5+A0Nz3NRsXJibnYi7brE/4tx5But9kkFGzG+xpUmimN4c3TMN7OFH//+r8hBf7BT9/GmHDUVZT2JzWGLZES2xDOUuMtA="},
            Content => '{"hello": "world"}'
    );

    my $p;
    try {
        $p = Authen::HTTP::Signature::Parser->new($req)->parse();
    }
    catch {
        die "Parse failed: $_\n";
    };

    my $key_string = read_file("/my/pub/key.pem") or die $!;
    $p->key( $key_string );

    if ( $p->verify() ) {
        say "Request is valid!"
    }
    else {
        say "Request isn't valid";
    };

=head1 PURPOSE

This is an implementation of the IETF HTTP Signatures specification authentication scheme. The idea is to authenticate
connections (over HTTPS ideally) using either an RSA keypair or a symmetric key by signing a set of header
values.

If you wish to use SSH keys for validation as in Joyent's proposal, check out L<Convert::SSH2>.

=head1 ATTRIBUTES

These are Perlish mutators; give an argument to set a value or no argument to get the current value.

=over

=item algorithm

The algorithm to use for signing. Read-only.

One of:

=over

=item * C<rsa-sha1>

=item * C<rsa-sha256> (B<default>)

=item * C<rsa-sha512>

=item * C<hmac-sha1>

=item * C<hmac-sha256>

=item * C<hmac-sha512>

=back

=back

=cut

has 'algorithm' => (
    is => 'ro',
    isa => sub {
        my $n = lc shift;
        confess "$n doesn't match any supported algorithm.\n" unless
            scalar grep { $_ eq $n } qw(
                rsa-sha1
                rsa-sha256
                rsa-sha512
                hmac-sha1
                hmac-sha256
                hmac-sha512
            );
    },
    default => sub { 'rsa-sha256' },
);

=over

=item headers

The list of headers to be signed (or already signed.) Defaults to the 'Date' header. The order of the headers
in this list will be used to build the order of the text in the signing string.

This attribute can have a psuedo-value. It is:

=over

=item * C<request-line>

Use the method, text of the path and query from the request, and the protocol version signature
(i.e., C</foo?param=value&pet=dog HTTP/1.1>) as part of the signing string.

=back

=over

=item * C<(request-target)>

Use the method, text of the path and query from the request
(i.e., C<get /foo?param=value&pet=dog>) as part of the signing string.

=back

=back

=cut

has 'headers' => (
    is => 'rw',
    isa => sub { confess "The 'headers' attribute expects an arrayref.\n" unless ref($_[0]) eq ref([]) },
    default => sub { [ 'date' ] },
);

=over

=item signing_string

The string used to compute the signature digest. It contents are derived from the
values of the C<headers> array.

=back

=cut

has 'signing_string' => (
    is => 'rw',
    predicate => 'has_signing_string',
);

=over

=item signature

Contains the digital signature authorization data.

=back

=cut

has 'signature' => (
    is => 'rw',
    predicate => 'has_signature',
);

=over

=item extensions

There are currently no extentions implemented by this library, but the library will append extension
information to the generated header data if this attribute has a value.

=back

=cut

has 'extensions' => (
    is => 'rw',
    predicate => 'has_extensions',
);


=over

=item key

The key to use for cryptographic operations.  The key type may have specific meaning based
on the algorithm used. RSA requires private keys for signing and the corresponding public
key for validation.  See the specific implementation module for more details about what this
value should be.

=back

=cut

has 'key' => (
    is => 'rw',
    predicate => 'has_key',
);

=over

=item key_id

Required.

A means to identify the key being used to both sender and receiver. This can be any token which makes
sense to the sender and receiver. The exact specification of a token and any necessary key management
are outside the scope of this library.

=back

=cut

has 'key_id' => (
    is => 'rw',
    predicate => 'has_key_id',
    required => 1,
);

=over

=item request

Holds the request to be parsed. Should be some kind of 'Request' object with an interface to
get/set headers.

=back

=cut

has 'request' => (
    is => 'rw',
    isa => sub { confess "'request' argument isn't blessed" unless blessed($_[0]) },
    predicate => 'has_request',
);

=over

=item get_header

Expects a C<CODE> reference.

This callback represents the method to get header values from the object in the C<request> attribute.

The request will be the first parameter, and name of the header to fetch a value will be provided
as the second parameter to the callback.

B<NOTE>: The callback should be prepared to handle a "pseudo-header" of C<request-line> which
is the path and query portions of the request's URI and HTTP version string.
(For more information see the
L<HTTP signature specification|https://github.com/joyent/node-http-signature/blob/master/http_signing.md>.)

=back

=cut

has 'get_header' => (
    is => 'rw',
    isa => sub { die "'get_header' expects a CODE ref\n" unless ref($_[0]) eq "CODE" },
    predicate => 'has_get_header',
    default => sub {
        sub {
            confess "Didn't get 2 arguments" unless @_ == 2;
            my $request = shift;
            confess "'request' isn't blessed" unless blessed $request;
            my $name = lc(shift);

            if( $name eq 'request-line' ) {
                sprintf("request-line: %s %s",
                    $request->uri->path_query,
                    $request->protocol);
            } elsif( $name eq '(request-target)' ) {
                sprintf("(request-target): %s %s",
                    lc($request->method),
                    $request->uri->path_query);
            } elsif( $request->header($name) ) {
                sprintf("%s: %s",
                    $name,
                    $request->header($name) );
            }
        };
    },
    lazy => 1,
);

=over

=item set_header

Expects a C<CODE> reference.

This callback represents the way to set header values on the object in the C<request> attribute.

The request will be the first parameter.  The name of the header and its value will be the second and
third parameters.

Returns the request object.

=back

=cut

has 'set_header' => (
    is => 'rw',
    isa => sub { die "'set_header' expects a CODE ref\n" unless ref($_[0]) eq "CODE" },
    predicate => 'has_set_header',
    default => sub {
        sub {
            confess "Didn't get 3 arguments" unless @_ == 3;
            my ($request, $name, $value) = @_;
            confess "'request' isn't blessed" unless blessed $request;

            $request->header( $name => $value );

            $request;
        };
    },
    lazy => 1,
);

=over

=item authorizaton_string

The text to identify the HTTP signature authorization scheme. Currently defined as the string
literal 'Signature'.  Read-only.

=back

=cut

has 'authorization_string' => (
    is => 'ro',
    default => sub { 'Signature' },
);

=head1 METHODS

Errors are generally fatal. Use L<Try::Tiny> for more graceful error handling.

=cut

sub _update_signing_string {
    my $self = shift;
    my $request = shift || $self->request;

    confess "I can't update the signing string because I don't have a request" unless $request;
    confess "I can't update the signing string because I don't have a 'get_header' callback" unless $self->has_get_header;

    my $ss = join "\n", map {
        $self->get_header->($request, $_)
            or confess "Couldn't get header value for $_\n" } @{ $self->headers };

    $self->signing_string( $ss );

    return $ss;
}

sub _format_signature {
    my $self = shift;

    my $rv = sprintf(q{%s keyId="%s",algorithm="%s"},
                $self->authorization_string,
                $self->key_id,
                $self->algorithm
             );

    if ( scalar @{ $self->headers } == 1 and $self->headers->[0] =~ /^date$/i ) {
        # if there's only the default header, omit the headers param
    }
    else {
        $rv .= q{,headers="} . lc(join " ", @{$self->headers}) . q{"};
    }

    if ( $self->has_extensions ) {
        $rv .= q{,ext="} . $self->extensions . q{"};
    }

    $rv .= q{,signature="} . $self->signature . q{"};

    return $rv;

}

=over

=item sign()

This method takes signs the values of the specified C<headers> using C<algorithm> and C<key>.

By default, it uses C<request> as its input. You may optionally pass a request object and it
will use that instead.  By default, it uses C<key>. You may optionally pass key material and it
will use that instead.

It will add a C<Date> header to the C<request> if there isn't already one in the request
object.

It adds a C<Authorization> header with the appropriate signature data.

The return value is a signed request object.

=back

=cut

sub sign {
    my $self = shift;

    my $request = shift || $self->request;
    confess "I don't have a request to sign" unless $request;

    my $key = shift || $self->key;
    confess "I don't have a key to use for signing" unless $key;

    unless ( $self->get_header->($request, 'date') ) {
        $self->set_header->($request, 'date', time2str());
    }

    $self->_update_signing_string($request);

    my $signer;
    if ( $self->algorithm =~ /^rsa/ ) {
        require Authen::HTTP::Signature::Method::RSA;
        $signer = Authen::HTTP::Signature::Method::RSA->new(
                    key => $key,
                    data => $self->signing_string,
                    hash => $self->algorithm
        );
    }
    elsif ( $self->algorithm =~ /^hmac/ ) {
        require Authen::HTTP::Signature::Method::HMAC;
        $signer = Authen::HTTP::Signature::Method::HMAC->new(
                    key => $key,
                    data => $self->signing_string,
                    hash => $self->algorithm
        );
    }
    else {
        confess "I don't know how to sign using " . $self->algorithm;
    }

    $self->signature( $signer->sign() );

    $self->set_header->($request, 'Authorization', $self->_format_signature);

    return $request;
}

=over

=item verify()

This method verifies that a signature on a request is valid.

By default it uses C<key>.  You may optionally pass in key material and it
will use that instead.

Returns a boolean.

=back

=cut

sub verify {
    my $self = shift;

    my $key = shift || $self->key;
    confess "I don't have a key to use for verification" unless $key;

    confess "I don't have a signing string" unless $self->has_signing_string;
    confess "I don't have a signature" unless $self->has_signature;

    my $v;
    if ( $self->algorithm =~ /^rsa/ ) {
        require Authen::HTTP::Signature::Method::RSA;
        $v = Authen::HTTP::Signature::Method::RSA->new(
                    key => $key,
                    data => $self->signing_string,
                    hash => $self->algorithm
        );
    }
    elsif ( $self->algorithm =~ /^hmac/ ) {
        require Authen::HTTP::Signature::Method::HMAC;
        $v = Authen::HTTP::Signature::Method::HMAC->new(
                    key => $key,
                    data => $self->signing_string,
                    hash => $self->algorithm
        );
    }
    else {
        confess "I don't know how to verify using " . $self->algorithm;
    }

    return $v->verify($self->signature);
}

=head1 AUTHOR

Mark Allen, C<< <mrallen1 at yahoo.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-authen-http-signature at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Authen-HTTP-Signature>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Authen::HTTP::Signature

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Authen-HTTP-Signature>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Authen-HTTP-Signature>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Authen-HTTP-Signature>

=item * MetaCPAN

L<https://metacpan.org/dist/Authen-HTTP-Signature/>

=item * GitHub

L<https://github.com/mrallen1/Authen-HTTP-Signature/>

=back

=head1 SEE ALSO

L<Authen::HTTP::Signature::Parser>,
L<Authen::HTTP::Signature::Method::HMAC>,
L<Authen::HTTP::Signature::Method::RSA>

L<Joyent's HTTP Signature specification|https://github.com/joyent/node-http-signature/blob/master/http_signing.md>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Mark Allen.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Authen::HTTP::Signature
