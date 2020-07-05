# NAME

Authen::TOTP - Interface to RFC6238 two factor authentication (2FA)

Version 0.0.7

# SYNOPSIS

    use Authen::TOTP;

# DESCRIPTION

`Authen::TOTP` is a simple interface for creating and verifying RFC6238 OTPs
as used by Google Authenticator, Authy, Duo Mobile etc

It currently passes RFC6238 Test Vectors for SHA1, SHA256, SHA512

# USAGE

    my $gen = new Authen::TOTP(
            secret         =>      "some_random_stuff",
    );

    #will generate a TOTP URI, suitable to use in a QR Code
    my $uri = $gen->generate_otp(user => 'user\@example.com', issuer => "example.com");
    
    print qq{$uri\n};
    #store $gen->secret() or $gen->base32secret() someplace safe!

    #use Imager::QRCode to plot the secret for the user
    use Imager::QRCode;
    my $qrcode = Imager::QRCode->new(
              size          => 4,
              margin        => 3,
              level         => 'L',
              casesensitive => 1,
              lightcolor    => Imager::Color->new(255, 255, 255),
              darkcolor     => Imager::Color->new(0, 0, 0),
          );

    my $img = $qrcode->plot($uri);
    $img->write(file => "totp.png", type => "png");
    #...or you can pass it to google charts and be done with it

    #compare user's OTP with computed one
    if ($gen->validate_otp(otp => <user_input>, secret => <stored_secret>, tolerance => 1)) {
           #2FA success
    }
    else {
           #no match
    }

# new Authen::TOTP

    my $gen = new Authen::TOTP(
            digits         =>      [6|8],
            period         =>      [30|60],
            algorithm      =>      "SHA1", #SHA256 and SHA512 are equally valid
            secret         =>      "some_random_stuff",
            when           =>      <some_epoch>,
            tolerance      =>      0,
    );

## Parameters/Properties (defaults listed)

- digits

    `6`=> How many digits to produce/compare

- period

    `30`=> OTP is valid for this many seconds

- algorithm

    `SHA1`=> supported values are SHA1, SHA256 and SHA512, although most clients only support SHA1 AFAIK

- secret

    `random_20byte_string`=> Secret used as seed for the OTP

- base32secret

    `base32_encoded_random_12byte_string`=> Alternative way to set secret (base32 encoded)

- when

    `epoch`=> Time used for comparison of OTPs

- tolerance

    `1`=> Due to time sync issues, you may want to tune this and compare
    this many OTPs before and after

## Utility Functions

- `generate_otp`=>

    Create a TOTP URI using the parameters specified or the defaults from
    the new() method above

    Usage:

        $gen->generate_otp(
                digits         =>      [6|8],
                period         =>      [30|60],
                algorithm      =>      "SHA1", #SHA256 and SHA512 are equally valid
                secret         =>      "some_random_stuff",
                issuer         =>      "example.com",
                user           =>      "some_identifier",
        );
        
        Google Authenticator displays <issuer> (<user>) for a TOTP generated like this

- `validate_otp`=>

    Compare a user-supplied TOTP using the parameters specified. Obviously the secret
    MUST be the same secret you used in generate\_otp() above/
    Returns 1 on success, undef if OTP doesn't match

    Usage:

        $gen->validate_otp(
                digits         =>      [6|8],
                period         =>      [30|60],
                algorithm      =>      "SHA1", #SHA256 and SHA512 are equally valid
                secret         =>      "the_same_random_stuff_you_used_to_generate_the_TOTP",
                when           =>      <epoch_to_use_as_reference>,
                tolerance      =>      <try this many iterations before/after when>
                otp            =>      <OTP to compare to>
        );
        

# Revision History

    0.0.7
           Moved git repo to github
           Added CONTRIBUTING.md file
           Changed gen_secret() to accept secret length as argument and made 20 the default
    0.0.6
           Another pointless adjustment in cpanfile
    0.0.5
           Corrected cpanfile to require either MIME::Base32::XS or MIME::Base32
           and Digest::SHA or Digest::SHA::PurePerl
    0.0.4
           Added missing test vectors
    0.0.3
           Switched to Digest::SHA in order to support SHA256 and SHA512 as well
    0.0.2
           Added Digest::HMAC_SHA1 and MIME::Base32 to cpanfiles requires (still
           getting acquainted with Minilla)
    0.0.1
           Initial Release

# DEPENDENCIES

one of 
[Digest::SHA](https://metacpan.org/pod/Digest%3A%3ASHA) or [Digest::SHA::PurePerl](https://metacpan.org/pod/Digest%3A%3ASHA%3A%3APurePerl)

and
[MIME::Base32::XS](https://metacpan.org/pod/MIME%3A%3ABase32%3A%3AXS) or [MIME::Base32](https://metacpan.org/pod/MIME%3A%3ABase32)

[Imager::QRCode](https://metacpan.org/pod/Imager%3A%3AQRCode) if you want to generate QRCodes as well

# SEE ALSO

[Auth::GoogleAuth](https://metacpan.org/pod/Auth%3A%3AGoogleAuth) for a module that does mostly the same thing

[https://tools.ietf.org/html/rfc6238](https://tools.ietf.org/html/rfc6238) for more info on TOTPs

# CAVEATS

Some stuff definitely isn't as efficient as it can be

# BUGS

Well, it passes RFC test vectors and has so far proven compatible with
Gitlab's 2FA.
Let me know if you find anything that's not working

# ACKNOWLEDGEMENTS

Github user j256 for his example implementation

Gryphon Shafer <gryphon@cpan.org> for his [Auth::GoogleAuth](https://metacpan.org/pod/Auth%3A%3AGoogleAuth) module
that does mostly the same job, but I discovered after I had written 
most of this

# AUTHOR

Thanos Chatziathanassiou <tchatzi@arx.net>
[http://www.arx.net](http://www.arx.net)

# COPYRIGHT

Copyright (c) 2020 arx.net - Thanos Chatziathanassiou . All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See [http://www.perl.com/perl/misc/Artistic.html](http://www.perl.com/perl/misc/Artistic.html)
