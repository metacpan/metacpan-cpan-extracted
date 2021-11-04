[![Build Status](https://travis-ci.org/akiym/Crypt-OpenSSL-Guess.svg?branch=master)](https://travis-ci.org/akiym/Crypt-OpenSSL-Guess)
# NAME

Crypt::OpenSSL::Guess - Guess OpenSSL include path

# SYNOPSIS

    use ExtUtils::MakerMaker;
    use Crypt::OpenSSL::Guess;

    WriteMakefile(
        # ...
        LIBS => ['-lssl -lcrypto ' . openssl_lib_paths()],
        INC  => openssl_inc_paths(), # guess include path or get from $ENV{OPENSSL_PREFIX}
    );

# DESCRIPTION

Crypt::OpenSSL::Guess provides helpers to guess OpenSSL include path on any platforms.

Often macOS's homebrew OpenSSL cause a problem on installation due to include path is not added.
Some CPAN module provides to modify include path with configure-args, but [Carton](https://metacpan.org/pod/Carton) or [Module::CPANfile](https://metacpan.org/pod/Module%3A%3ACPANfile)
is not supported to pass configure-args to each modules. Crypt::OpenSSL::\* modules should use it on your [Makefile.PL](https://metacpan.org/pod/Makefile.PL).

This module resolves the include path by [Net::SSLeay](https://metacpan.org/pod/Net%3A%3ASSLeay)'s workaround.
Original code is taken from `inc/Module/Install/PRIVATE/Net/SSLeay.pm` by [Net::SSLeay](https://metacpan.org/pod/Net%3A%3ASSLeay).

# FUNCTIONS

- openssl\_inc\_paths()

    This functions returns include paths in the format passed to CC. If OpenSSL could not find, then empty string is returned.

        openssl_inc_paths(); # on macOS: "-I/usr/local/opt/openssl/include"

- openssl\_lib\_paths()

    This functions returns library paths in the format passed to CC. If OpenSSL could not find, then empty string is returned.

        openssl_lib_paths(); # on macOS: "-L/usr/local/opt/openssl/lib"

- find\_openssl\_prefix(\[$dir\])

    This function returns OpenSSL's prefix. If set `OPENSSL_PREFIX` environment variable, you can overwrite the return value.

        find_openssl_prefix(); # on macOS: "/usr/local/opt/openssl"

- find\_openssl\_exec($prefix)

    This functions returns OpenSSL's executable path.

        find_openssl_exec(); # on macOS: "/usr/local/opt/openssl/bin/openssl"

- ($major, $minor, $letter) = openssl\_version()

    This functions returns OpenSSL's version as major, minor, letter.

        openssl_version(); # ("1.0", "2", "n")

# SEE ALSO

[Net::SSLeay](https://metacpan.org/pod/Net%3A%3ASSLeay)

# LICENSE

Copyright (C) Takumi Akiyama.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Takumi Akiyama <t.akiym@gmail.com>
