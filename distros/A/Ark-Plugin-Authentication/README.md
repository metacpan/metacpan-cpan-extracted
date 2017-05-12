# NAME

Ark::Plugin::Authentication - Ark plugins for authentications

# SYNOPSIS

    use Ark;
    use_plugins qw/
        Session
        Session::State::Cookie
        Session::Store::Memory

        Authentication
        Authentication::Credential::Password
        Authentication::Store::Minimal
    /;
    conf 'Plugin::Authentication::Store::Minimal' => {
        users => {
            user1 => { username => 'user1', password => 'pass1', },
            user2 => { username => 'user2', password => 'pass2', },
        },
    };

# DESCRIPTION

Ark::Plugin::Authentication is Ark plugins for Authentications.

# LICENSE

Copyright (C) Songmu.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Daisuke Murase <typester@cpan.org>

Songmu <y.songmu@gmail.com>
