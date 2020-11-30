# NAME

Amon2::Auth::Site::LINE - LINE integration for Amon2

# SYNOPSIS

\# in your configuration file

    +{
        Auth => {
            LINE => {
                client_id     => '123456789Z',,
                client_secret => '01234567889abcdef0123456789abcdx',
                scope         => [qw(profile)],
            }
        }
    }

\# in your web app

    __PACKAGE__->load_plugin('Web::Auth', {
        module => 'LINE',
        on_finished => sub {
            my($c, $token, $api_response) = @_;
            my $user_id = $api_response->{userId};
            my $name    = $api_response->{displayName};
            $c->session->set(user_id => $user_id);
            $c->session->set(name    => $name);
            return $c->redirect('/');
        },
        on_error => sub {
            my($c, $error_message) = @_;
            ...
        }
    });
    

# DESCRIPTION

This is a LINE Login authentication module for Amon2.
It uses LINE Login v2.1 APIs.

# ATTRIBUTES FOR CONFIGURATION FILE

Following attributes are set in your configuration file such like `config/production.pl` and so on.

- client\_id

    Mandatory. It is issued on LINE Developers Console.

- client\_secret

    Mandatory. It is issued on LINE Developers Console.

- redirect\_uri

    Optional. It's used for some API's `redirect_uri` parameter.
    If it's ommited, `callback_path` which is passed as an attribute for argument is used instead of it.

- state

    Optional. If you don't set nothing, it generates a random string.
    The `state` parameter is used a system for preventing CSRF on OAuth 2.0. This attribute should not be set some foreseeable fixed value.

- scope

    API scope as an array-ref.
    Acceptable values are: `profile`, `openid` and `email`.
    See detail: [https://developers.line.biz/en/docs/line-login/integrate-line-login/#scope](https://developers.line.biz/en/docs/line-login/integrate-line-login/#scope)
    Default value is `['profile']`.

- nonce

    Optional. If you don't set nothing, it generates a random string.
    The `nonce` parameter is used a system for preventing replay attack / token interception attack on OpenID Connect. This attribute should not be set some foreseeable fixed value.

- prompt

    Optional. `consent` is acceptable.

- max\_age

    Optional. Specified on OpenID Conjnect Core 1.0.

- ui\_locales

    Optional. Specified on OpenID Conjnect Core 1.0.

- bot\_prompt

    Optional. `normal` and `aggressive` are acceptable.

- state\_session\_key

    Optional. `state` parameter is kept on session with this specified session key during authentication.
    Default values `line_login_state`.

- nonce\_session\_key

    Optional. `nonce` parameter is kept on session with this specified session key during.
    Default values `line_login_nonce`.

# ATTRIBUTES FOR ARGUMENT

- authenticate\_path

    Optional. Default value is `/auth/line/authenticate`. The path works for "login link".

- callback\_path

    Optional. Default value is `/auth/line/callback`.

- on\_finished

    Mandatory. The details are described following.

- on\_error

    Optional. The details are described following.

- user\_info

    Optional. If it's true, this module fetches the user information after authentication.

# METHODS

- `$auth->auth_uri($c:Amon2::Web, $callback_uri : Str) :Str`

    Get a authenticate URI.

- `$auth->callback($c:Amon2::Web, $callback:HashRef) : Plack::Response`

    Process the authentication callback dispatching.

    `$callback` MUST have two keys.

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
                my ($c, $access_token, $api_response) = @_;
                ...
            }

        `$api_response` contains an issued access token, a verified access token validity, and a gotten user profile. And they are all merged into one hash-ref.
        This code contains a information like [https://developers.line.biz/en/reference/line-login/#issue-token-response](https://developers.line.biz/en/reference/line-login/#issue-token-response), [https://developers.line.biz/en/reference/line-login/#verify-access-token-response](https://developers.line.biz/en/reference/line-login/#verify-access-token-response) and [https://developers.line.biz/en/reference/line-login/#get-profile-response](https://developers.line.biz/en/reference/line-login/#get-profile-response).
        If you set `$auth->user_info` as a false value and/or you don't set `profile` as the `scope` attribute, authentication engine does not pass a gotten user profile.

# AUTHOR

Koichi Taniguchi (a.k.a. nipotan) <taniguchi@cpan.org>

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# SEE ALSO

- LINE Login v2.1 API Reference

    [https://developers.line.biz/en/reference/line-login/](https://developers.line.biz/en/reference/line-login/)

- Amon2::Plugin::Web::Auth

    [Amon2::Plugin::Web::Auth](https://metacpan.org/pod/Amon2::Plugin::Web::Auth)
