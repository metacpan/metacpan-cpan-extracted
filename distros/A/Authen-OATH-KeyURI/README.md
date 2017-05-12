# NAME

Authen::OATH::KeyURI - Key URI generator for mobile multi factor authenticator app

# SYNOPSIS

    use Authen::OATH::KeyURI;

    # constructor
    my $keyURI = Authen::OATH::KeyURI->new(
        ## required params
        accountname => q{alice@gmail.com},
        secret       => q{example secret}, # raw secret
        issuer      => q{Example},
        ## optional params
        # scheme      => q{otpauth},
        # type        => q{totp},
        # algorithm   => q{SHA1},
        # digits      => 6,
        # counter     => 1,
        # period      => 30,
    );

    # output
    # format : otpauth://TYPE/LABEL?PARAMETERS
    print $keyURI->as_string();
    # otpauth://totp/Example:alice@google.com?secret=mv4gc3lqnrssa43fmnzgk5a&issuer=Example

    # constructor with encoded secret
    my $keyURI = Authen::OATH::KeyURI->new(
        ## required params
        accountname => q{alice@gmail.com},
        secret       => q{mv4gc3lqnrssa43fmnzgk5a}, # base32 encoded secret
        issuer      => q{Example},
        is_encoded  => 1,
    );

    # output
    # format : otpauth://TYPE/LABEL?PARAMETERS
    print $keyURI->as_string();
    # otpauth://totp/Example:alice@google.com?secret=mv4gc3lqnrssa43fmnzgk5a&issuer=Example

# DESCRIPTION

Authen::OATH::KeyURI generates a setting URL for software OTP authenticator.

Please refer to a document of Google for the details of parameter.

[https://code.google.com/p/google-authenticator/wiki/KeyUriFormat](https://code.google.com/p/google-authenticator/wiki/KeyUriFormat)

# LICENSE

Copyright (C) ritou.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

ritou <ritou.06@gmail.com>
