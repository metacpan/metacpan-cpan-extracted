# NAME

Amon2::Auth::Site::Hatena - Hatena authentication integration for Amon2

# SYNOPSIS

    # config
    +{
        Auth => {
            Hatena => {
                consumer_key    => 'your consumer key',
                consumer_secret => 'your consumer secret',
            }
        }
    }

    # app
    __PACKAGE__->load_plugin('Web::Auth', {
        module   => 'Hatena',
        on_error => sub {
            my ($c, $error_message) = @_;
            ...
        },
        on_finished => sub {
            my ($c, $token, $token_secret, $user) = @_;

            my $name  = $user->{url_name};     #=> eg. antipop (id)
            my $nick  = $user->{display_name}; #=> eg. kentaro (nick)
            my $image = $user->{profile_image_url};

            $c->session->set(hatena => {
                user         => $user,
                token        => $token,
                token_secret => $token_secret,
            });

            $c->redirect('/');
        },
    });

# DESCRIPTION

This is a Hatena authentication module for Amon2. You can easily let
users authenticate via Hatena OAuth API using this module.

# ATTRIBUTES

- consumer\_key (required)
- comsumer\_secret (required)
- scope (Default: `[qw(read_public)]`)

    API scope in ArrayRef.

- user\_info (Default: true)

    If true, this module fetch user data immediately after authentication.

- ua (Default: instance of OAuth::Lite::Consumer)

# METHODS

- `$auth->auth_uri($c:Amon2::Web, $callback_uri:Str)` : Str

    Returns an authenticate URI according to `$ENV{HTTP_USER_AGENT}`. It
    can be one of three for PC, smart phone, and JP cell phone.

- `$auth->callback($c:Amon2::Web, $callback:HashRef)` : Plack::Response

    Process the authentication callback dispatching.

    - on\_error

        _on\_error_ callback function is called if an error was occurred.

        The arguments are following:

            sub {
                my ($c, $error_message) = @_;
                ...
            }

    - on\_finished

        _on\_finished_ callback function is called if an authentication was
        finished.

        The arguments are following:

            sub {
                my ($c, $access_token, $access_token_secret, $user) = @_;
                ...
            }

        `$user` contains user information. If you set `$auth-`user\_info> as
        a false value, authentication engine does not pass `$user`.

        See ["app.psgi" in eg](https://metacpan.org/pod/eg#app.psgi) for details.

# SEE ALSO

- Hatena Auth Specification

    [http://developer.hatena.ne.jp/ja/documents/auth](http://developer.hatena.ne.jp/ja/documents/auth)

# AUTHOR

Kentaro Kuribayashi <kentarok@gmail.com>

# LICENSE

Copyright (C) Kentaro Kuribayashi

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
