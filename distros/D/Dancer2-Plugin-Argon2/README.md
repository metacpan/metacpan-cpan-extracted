# NAME

Dancer2::Plugin::Argon2 - Handling Argon2 passwords in Dancer2

# SYNOPSIS

    use Dancer2::Plugin::Argon2;

    my $passphrase = passphrase($password)->encoded;
    if ( passphrase($password2)->matches($passphrase) ) { ... }

# DESCRIPTION

Dancer2::Plugin::Argon2 is a plugin for Dancer2 to manage passwords using Argon2.

# CONFIGURATION

The module can be used with the default configuration.
But it is possible to change it if necessary.
The default configuration may present like this:

    plugins:
        Argon2:
            cost: 3
            factor: '32M'
            parallelism: 1
            size: 16

# USAGE

    package SomeWebApplication;
    use Dancer2;
    use Dancer2::Plugin::Argon2;

    post '/signup' => sub {
        my $passphrase = passphrase( body_parameters->get('password') )->encoded;
        # and store $passphrase for use later
    };

    post '/login' => sub {
        # retrieve stored passphrase into $passphrase
        if ( passphrase( body_parameters->get('password') )->matches($passphrase) ) {
            # passphrase matches
        }
    };

# SEE ALSO

[Dancer2::Plugin::Argon2::Passphrase](https://metacpan.org/pod/Dancer2::Plugin::Argon2::Passphrase),
[Crypt::Argon2](https://metacpan.org/pod/Crypt::Argon2),
[https://github.com/p-h-c/phc-winner-argon2](https://github.com/p-h-c/phc-winner-argon2)

# LICENSE

Copyright (C) Sergiy Borodych.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Sergiy Borodych `<bor at cpan.org>`
