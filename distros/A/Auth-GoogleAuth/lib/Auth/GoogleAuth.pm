package Auth::GoogleAuth;
# ABSTRACT: Google Authenticator TBOT Abstraction

use 5.008;
use strict;
use warnings;

use base 'Class::Accessor';

use Digest::HMAC_SHA1 'hmac_sha1_hex';
use Math::Random::MT 'rand';
use URI::Escape 'uri_escape';
use Convert::Base32 qw( encode_base32 decode_base32 );
use Carp 'croak';

our $VERSION = '1.03'; # VERSION

my @accessors = qw( secret secret32 issuer key_id otpauth );
__PACKAGE__->mk_accessors(@accessors);

sub generate_secret32 {
    my ($self) = @_;
    my @chars = ( 'a' .. 'z', 2 .. 7 );
    return $self->secret32( join( '', @chars[ map { rand( scalar(@chars) ) } 1 .. 16 ] ) );
}

sub clear {
    my ($self) = @_;
    $self->$_(undef) for (@accessors);
    return;
}

sub qr_code {
    my ( $self, $secret32, $key_id, $issuer, $return_otpauth ) = @_;
    $self->_secret_check($secret32);

    $self->key_id($key_id) if ($key_id);
    $self->issuer($issuer) if ($issuer);

    $self->key_id('Undefined') unless ( $self->key_id );
    $self->issuer('Undefined') unless ( $self->issuer );

    $self->otpauth(
        'otpauth://totp/' .
        uri_escape( $self->issuer ) . ':' . uri_escape( $self->key_id ) .
        '?secret=' . $self->secret32 . '&issuer=' . uri_escape( $self->issuer )
    );

    return ($return_otpauth)
        ? $self->otpauth
        : 'https://chart.googleapis.com/chart?chs=200x200&cht=qr&chl=' . uri_escape( $self->otpauth );
}

sub code {
    my ( $self, $secret32, $timestamp, $interval ) = @_;
    $self->_secret_check($secret32);

    $timestamp ||= time;
    $interval  ||= 30;

    my $hmac = hmac_sha1_hex(
        pack( 'H*', sprintf( '%016x', int( $timestamp / $interval ) ) ),
        _decode_base32( $self->secret32 ),
    );

    return sprintf(
        '%06d',
        ( hex( substr( $hmac, hex( substr( $hmac, -1 ) ) * 2, 8 ) ) & 0x7fffffff ) % 1000000
    );
}

sub verify {
    my ( $self, $code, $range, $secret32, $timestamp, $interval ) = @_;
    $self->_secret_check($secret32);

    $code      ||= '';
    $range     ||= 0;
    $timestamp ||= time;
    $interval  ||= 30;

    croak('Range value not zero or a positive number') unless ( $range =~ /^\d+$/ and $range >= 0 );

    for ( 0 .. $range ) {
        return 1 if (
            not $_ and $code eq $self->code( $secret32, $timestamp, $interval )
            or
            $code eq $self->code( $secret32, $timestamp + $interval * $_, $interval )
            or
            $code eq $self->code( $secret32, $timestamp - $interval * $_, $interval )
        );
    }

    return 0;
}

sub _secret_check {
    my ( $self, $secret32 ) = @_;

    if ($secret32) {
        $self->secret32($secret32);
        $self->secret( _decode_base32($secret32) );
    }

    if ( not $self->secret32 ) {
        if ( not $self->secret ) {
            $self->secret( _decode_base32( $self->generate_secret32 ) );
        }
        else {
            $self->secret32( encode_base32( $self->secret ) );
        }
    }

    return;
}

sub _decode_base32 {
    my ($data) = @_;
    my $rv;
    eval{ $rv = decode_base32($data) };
    croak("Error decoding what should be base32 data: $data")
        if ( $@ =~ /Data contains non-base32 characters/ );
    return $rv;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Auth::GoogleAuth - Google Authenticator TBOT Abstraction

=head1 VERSION

version 1.03

=for markdown [![test](https://github.com/gryphonshafer/Auth-GoogleAuth/workflows/test/badge.svg)](https://github.com/gryphonshafer/Auth-GoogleAuth/actions?query=workflow%3Atest)
[![codecov](https://codecov.io/gh/gryphonshafer/Auth-GoogleAuth/graph/badge.svg)](https://codecov.io/gh/gryphonshafer/Auth-GoogleAuth)

=head1 SYNOPSIS

    use Auth::GoogleAuth;

    my $auth = Auth::GoogleAuth->new;

    $auth = Auth::GoogleAuth->new({
        secret => 'some secret string thing',
        issuer => 'Gryphon Shafer',
        key_id => 'gryphon@cpan.org',
    });

    $auth->secret();   # get/set
    $auth->secret32(); # get/set
    $auth->issuer();   # get/set
    $auth->key_id();   # get/set

    my $secret32 = $auth->generate_secret32;

    $auth->clear;

    my $url_0 = $auth->qr_code;
    my $url_1 = $auth->qr_code(
        'bv5o3disbutz4tl3', # secret32
        'gryphon@cpan.org', # key_id
        'Gryphon Shafer',   # issuer
    );
    my $url_2 = $auth->qr_code(
        'bv5o3disbutz4tl3', 'gryphon@cpan.org', 'Gryphon Shafer', 1,
    );

    my $otpauth = $auth->otpauth;

    my $code_0 = $auth->code;
    my $code_1 = $auth->code( 'utz4tl3bv5o3disb', 1438643789, 30 );

    my $verification_0 = $auth->verify('879364');
    my $verification_1 = $auth->verify(
        '879364',           # code
        1,                  # range
        'utz4tl3bv5o3disb', # secret32
        1438643820,         # timestamp (defaults to now)
        30,                 # interval (default 30)
    );

=head1 DESCRIPTION

This module provides a simplified interface to supporting typical two-factor
authentication (i.e. "2FA") with
L<Google Authenticator|https://en.wikipedia.org/wiki/Google_Authenticator>
using the
L<TOTP Algorithm|https://en.wikipedia.org/wiki/Time-based_One-time_Password_Algorithm>
as defined by L<RFC 6238|http://tools.ietf.org/html/rfc6238>.
Although Google Authenticator supports both TOTP and HOTP, at the moment,
this module only supports TOTP.

=head1 METHODS

The following are the supported methods of this module:

=head2 new

This is a simple instantiator to which you can pass optional default values.

    my $auth = Auth::GoogleAuth->new;

    $auth = Auth::GoogleAuth->new({
        secret => 'some secret string thing',
        issuer => 'Gryphon Shafer',
        key_id => 'gryphon@cpan.org',
    });

The object returned will support the following attribute get/set methods:

=head3 secret

This can be any string. It'll be used as the internal secret key to create
the QR codes and authentication codes.

=head3 secret32

This is a base-32 encoded copy of the secret string. If this is left undefined
and you run one of the methods that require it (like C<qr_code> or C<code>),
the method called will try to create the "secret32" by looking for a value in
"secret". If none exists, a random "secret32" will be generated.

=head3 issuer

This is the label name of the "issuer" of the authentication.
See the
L<key URI format wiki page|https://github.com/google/google-authenticator/wiki/Key-Uri-Format>
for more information.

=head3 key_id

This is the label name of the "key ID" of the authentication.
See the
L<key URI format wiki page|https://github.com/google/google-authenticator/wiki/Key-Uri-Format>
for more information.

=head3 otpauth

This method returns the otpauth key URI generated when you call
C<qr_code>.

=head2 generate_secret32

This method will generate a reasonable random "secret32" value, store it in the
get/set method, and return it.

    my $secret32 = $auth->generate_secret32;

=head2 clear

Given that the "secret" and "secret32" values may persist in this object, which
could be a bad idea in some contexts, this C<clear> method lets your clear out
all attribute values.

    $auth->clear;

=head2 qr_code

This method will return a Google Chart API URL that will return a QR code based
on the data either in the object or provided to this method.

    my $url_0 = $auth->qr_code;
    my $url_1 = $auth->qr_code(
        'bv5o3disbutz4tl3', # secret32
        'gryphon@cpan.org', # key_id
        'Gryphon Shafer',   # issuer
    );

You can optionally add a final true value, and if you do, the method will
return the generated otpauth key URI rather than the Google Chart API URL.

    my $url_2 = $auth->qr_code(
        'bv5o3disbutz4tl3', 'gryphon@cpan.org', 'Gryphon Shafer', 1,
    );

=head2 code

This method returns an authentication code, as if you were using
L<Google Authenticator|https://en.wikipedia.org/wiki/Google_Authenticator>
with the "secret32" value.

    my $code_0 = $auth->code;

You can optionally pass override values similar to C<qr_code>:

    my $code_1 = $auth->code(
        'utz4tl3bv5o3disb', # secret32
        1438643789,         # timestamp (defaults to now)
        30,                 # interval (default 30)
    );

=head2 verify

This method is used for verification of codes entered by a user. Pass in the
code (required) and optionally a range value and any override values.

    my $verification_0 = $auth->verify('879364');

The range value is useful because the algorithm checks codes that are time-
based. If clocks are not exactly in sync, it's possible that a "nearly valid"
code would be entered and should be accepted as valid but will be seen as
invalid. By passing in an integer as a range value, you can stipulate how
"fuzzy" the time should be. The default range is 0. A value of 1 will mean that
a code based on a time 1 iteration plus or minus should verify.

    my $verification_1 = $auth->verify(
        '879364',           # code
        1,                  # range
        'utz4tl3bv5o3disb', # secret32
        1438643820,         # timestamp (defaults to now)
        30,                 # interval (default 30)
    );

=head1 TYPICAL USE-CASE

Typically, you're probably going to want to either randomly generate a secret or
secret32 (C<generate_secret32>) for a user and store it, or use a specific value
or hash of some value as the secret. In either case, once you have a secret and
its stored, generate a QR code (C<qr_code>) for the user. You can alternatively
provide the "secret32" to the user for them to manually enter it. That's it
for setup.

To authenticate, present the user with a way to provide you a code (which will
be a series of 6-digits). Verify that code (C<verify>) with either no range
or some small range like 1.

=head1 DEPENDENCIES

L<Digest::HMAC_SHA1>, L<Math::Random::MT>, L<URI::Escape>, L<Convert::Base32>,
L<Class::Accessor>, L<Carp>.

=head1 SEE ALSO

You can look for additional information about this module at:

=over 4

=item *

L<GitHub|https://github.com/gryphonshafer/Auth-GoogleAuth>

=item *

L<MetaCPAN|https://metacpan.org/pod/Auth::GoogleAuth>

=item *

L<GitHub Actions|https://github.com/gryphonshafer/Auth-GoogleAuth/actions>

=item *

L<Codecov|https://codecov.io/gh/gryphonshafer/Auth-GoogleAuth>

=item *

L<CPANTS|http://cpants.cpanauthors.org/dist/Auth-GoogleAuth>

=item *

L<CPAN Testers|http://www.cpantesters.org/distro/G/Auth-GoogleAuth.html>

=back

You can look for additional information about things related to this module at:

=over 4

=item *

L<TOTP Algorithm|https://en.wikipedia.org/wiki/Time-based_One-time_Password_Algorithm>

=item *

L<RFC 6238|http://tools.ietf.org/html/rfc6238>

=item *

L<Google Authenticator|https://en.wikipedia.org/wiki/Google_Authenticator>

=item *

L<Google Authenticator GitHub|https://github.com/google/google-authenticator>

=back

=head1 AUTHOR

Gryphon Shafer <gryphon@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015-2021 by Gryphon Shafer.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
