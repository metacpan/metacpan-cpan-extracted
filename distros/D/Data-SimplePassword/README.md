# NAME

Data::SimplePassword - Simple random password generator

# SYNOPSIS

    use Data::SimplePassword;

    my $sp = Data::SimplePassword->new;
    $sp->chars( 0..9, 'a'..'z', 'A'..'Z' );    # optional

    my $password = $sp->make_password( 8 );    # length

# DESCRIPTION

YA very easy-to-use but a bit strong random password generator.

# METHODS

- **new**

        my $sp = Data::SimplePassword->new;

    Makes a Data::SimplePassword object.

- **chars**

        $sp->chars( 0..9, 'a'..'z', 'A'..'Z' );    # default
        $sp->chars( 0..9, 'a'..'z', 'A'..'Z', qw(+ /) );    # b64-like
        $sp->chars( 0..9 );
        my @c = $sp->chars;    # returns the current values

    Sets an array of characters you want to use as your password string.

- **make\_password**

        my $password = $sp->make_password( 8 );    # default
        my $password = $sp->make_password( 1024 );

    Makes password string and just returns it. You can set the byte length as an integer.

# EXTRA METHODS

- **provider**

        $sp->provider("devurandom");    # optional

    Sets a type of random number generator, see Crypt::Random::Provider::\* for details.

- **is\_available\_provider**

        $sp->is_available_provider("devurandom");

    Returns true when the type is available.

- **seed\_num**

        $sp->seed_num( 32 );    # up to 624

    Sets initial seed number (internal use only).

# COMMAND-LINE TOOL

A useful command named rndpassword(1) will be also installed. Type **man rndpassword** for details.

# DEPENDENCY

Moo, UNIVERSAL::require, Crypt::Random, Math::Random::MT (or Math::Random::MT::Perl),

# SEE ALSO

Crypt::GeneratePassword, Crypt::RandPasswd, String::MkPasswd, Data::Random::String, String::Random, Crypt::XkcdPassword, Session::Token

http://en.wikipedia.org/wiki//dev/random

# REPOSITORY

https://github.com/ryochin/p5-data-simplepassword

# AUTHOR

Ryo Okamoto &lt;ryo@aquahill.net>

# COPYRIGHT & LICENSE

Copyright (c) Ryo Okamoto, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
