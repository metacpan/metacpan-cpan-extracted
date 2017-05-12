# NAME

Authen::OATH - OATH One Time Passwords

# VERSION

version 2.0.1

# SYNOPSIS

    use Authen::OATH;

    my $oath = Authen::OATH->new();
    my $totp = $oath->totp( 'MySecretPassword' );
    my $hotp = $oath->hotp( 'MyOtherSecretPassword' );

Parameters may be overridden when creating the new object:

    my $oath = Authen::OATH->new( digits => 8 );

The three parameters are "digits", "digest", and "timestep."
Timestep only applies to the totp() function.

While strictly speaking this is outside the specifications of
HOTP and TOTP, you can specify digests other than SHA1. For example:

    my $oath = Authen::OATH->new(
        digits => 10,
        digest => 'Digest::MD6',
    );

If you are using Google Authenticator, you'll want to decode your secret
\*before\* passing it to the `totp` method:

    use Convert::Base32 qw( decode_base32 );

    my $oath = Authen::OATH->new;
    my $secret = 'mySecret';
    my $otp = $oath->totp(  decode_base32( $secret ) );

# DESCRIPTION

Implementation of the HOTP and TOTP One Time Password algorithms
as defined by OATH (http://www.openauthentication.org)

All necessary parameters are set by default, though these can be
overridden. Both totp() and htop() have passed all of the test
vectors defined in the RFC documents for TOTP and HOTP.

totp() and hotp() both default to returning 6 digits and using SHA1.
As such, both can be called by passing only the secret key and a
valid OTP will be returned.

# SUBROUTINES/METHODS

## totp

    my $otp = $oath->totp( $secret [, $manual_time ] );

Manual time is an optional parameter. If it is not passed, the current
time is used. This is useful for testing purposes.

## hotp

    my $opt = $oath->hotp( $secret, $counter );

Both parameters are required.

## \_process

This is an internal routine and is never called directly.

# CAVEATS

Please see the SYNOPSIS for how interaction with Google Authenticator.

# AUTHOR

Kurt Kincaid <kurt.kincaid@gmail.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2010-2017 by Kurt Kincaid.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
