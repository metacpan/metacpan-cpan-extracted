# NAME

Amon2::Auth::Site::Google - Google auth integration for Amon2

# SYNOPSIS

    #add config
    +{
        Auth => {
            Google => {
                client_id     => 'client id',
                client_secret => 'client secret',
                redirect_url  => 'redirect url',
                scope         => ['scope']
            }
        }
    }

    #add app
    __PACKAGE__->load_plugin('Web::Auth', {
        module => 'Google',
        on_finished => sub {
            my ($c, $access_token, $refresh_token, $user) = @_;

            my $id       = $user->{id};       #e.g. 123456789
            my $name     = $user->{name};     #e.g. Nao Takanashi
            my $birthday = $user->{birthday}; #e.g. 1988-07-25

            $c->session->set(google => +{
                access_token  => $access_token,
                refresh_token => $refresh_token,
                user          => $user,
            });

            return $c->redirect('/');
        },
        on_error => sub {
            my ($c, $error_message) = @_;
            ...
        },
    });

# DESCRIPTION

Amon2::Auth::Site::Google is a Google authenticate module for Amon2

# ATTRIBUTES

- client\_id (required)
- client\_secret (required)
- redirect\_url (required)
- scope (Default: \[qw(https://www.googleapis.com/auth/userinfo.profile)\])
- user\_info (Default: true)

    If true, this module fetch user data immediately after authentication.

# METHODS

- `$auth->auth_uri($c:Amon2::Web, $callback_uri : Str) :Str`
Get a authenticate URI.
- `$auth->callback($c:Amon2::Web, $callback:HashRef) : Plack::Response`
Process the authentication callback dispatching.
    - on\_error

        on\_error callback function is called when an error occurs.

        The arguments are following:

            sub {
                my ($c, $error_message) = @_;
                ...
            }

    - on\_finished

        on\_finished callback function is called if an authentication was finished.ck function is called After successful authentication.

        The arguments are following:

            sub {
                my ($c, $access_token, $refresh_token, $user) = @_;
                ...
            }

        If you set $auth-user\_info> as a false value, authentication engine does not pass $user.

# SEE ALSO

- Using OAuth 2.0 to Access Google APIs
[https://developers.google.com/accounts/docs/OAuth2](https://developers.google.com/accounts/docs/OAuth2)
- Amon2::Plugin::Web::Auth
[https://metacpan.org/module/TOKUHIROM/Amon2-Auth-0.03/lib/Amon2/Plugin/Web/Auth.pm](https://metacpan.org/module/TOKUHIROM/Amon2-Auth-0.03/lib/Amon2/Plugin/Web/Auth.pm)

# LICENSE

Copyright (C) ntakanashi.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

ntakanashi <ntakanashi666 at gmail.com>
