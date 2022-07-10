package Dancer2::Plugin::Auth::OAuth;

use strict;
use 5.008_005;
our $VERSION = '0.20';

use Dancer2::Plugin;
use Module::Load;

# setup the plugin
on_plugin_import {
    my $dsl      = shift;
    my $settings = plugin_setting;

    $settings->{prefix} ||= '/auth';

    for my $provider ( keys %{$settings->{providers} || {}} ) {

        # load the provider plugin
        my $provider_class = __PACKAGE__."::Provider::".$provider;
        eval { load $provider_class; 1; } or do {
            $dsl->app->log(debug => "Couldn't load $provider_class");
            next;
        };
        $dsl->app->{_oauth}{$provider} ||= $provider_class->new($settings, $dsl);

        # add the routes
        $dsl->app->add_route(
            method => 'get',
            regexp => sprintf( "%s/%s", $settings->{prefix}, lc($provider) ),
            code   => sub {
                $dsl->app->redirect(
                    $dsl->app->{_oauth}{$provider}->authentication_url(
                        $dsl->app->request->uri_base
                    )
                )
            },
        );
        $dsl->app->add_route(
            method => 'get',
            regexp => sprintf( "%s/%s/callback", $settings->{prefix}, lc($provider) ),
            code   => sub {
                my $redirect;
                if( $dsl->app->{_oauth}{$provider}->callback($dsl->app->request, $dsl->app->session) ) {
                    $redirect = $settings->{success_url} || '/';
                } else {
                    $redirect = $settings->{error_url}   || '/';
                }

                $dsl->app->redirect( $redirect );
            },
        );
        $dsl->app->add_route(
            method => 'get',
            regexp => sprintf( "%s/%s/refresh", $settings->{prefix}, lc($provider) ),
            code   => sub {
                my $redirect;
                if( $dsl->app->{_oauth}{$provider}->refresh($dsl->app->request, $dsl->app->session) ) {
                    $redirect = $settings->{success_url} || '/';
                } else {
                    if ($settings->{reauth_on_refresh_fail}) {
                        $redirect = $settings->{prefix}."/".lc($provider);
                    } else {
                        $redirect = $settings->{error_url}   || '/';
                    }
                }
                $dsl->app->redirect( $redirect );
            },
        );
    }
};

register_plugin;

1;
__END__

=encoding utf-8

=head1 NAME

Dancer2::Plugin::Auth::OAuth - OAuth for your Dancer2 app

=head1 SYNOPSIS

  # just 'use' the plugin, that's all.
  use Dancer2::Plugin::Auth::OAuth;

=head1 DESCRIPTION

Dancer2::Plugin::Auth::OAuth is a Dancer2 plugin which tries to make OAuth
authentication easy.

The module is highly influenced by L<Plack::Middleware::OAuth> and Dancer 1
OAuth modules, but unlike the Dancer 1 versions, this plugin only needs
configuration (look mom, no code needed!). It automatically sets up the
needed routes (defaults to C</auth/$provider> and C</auth/$provider/callback>).
So if you define the Twitter provider in your config, you should automatically
get C</auth/twitter> and C</auth/twitter/callback>.

After a successful OAuth dance, the user info is stored in the session "oauth".
What you do with it afterwards is up to you. Please note the user will
continue to be authenticated until the Dancer2 session has expired,
whenever that might be.

=head1 CONFIGURATION

The plugin comes with support for Facebook, Google, Twitter, GitHub, Stack
Exchange, LinkedIn and several more (other providers aren't hard to add,
send me a pull request when you add more!).

All it takes to use OAuth authentication for a given provider, is to add
the configuration for it. You don't need anything else.

The YAML below shows all available options.

  plugins:
    "Auth::OAuth":
      reauth_on_refresh_fail: 0 [*]
      prefix: /auth [*]
      success_url: / [*]
      error_url: / [*]
      providers:
        Facebook:
          tokens:
            client_id: your_client_id
            client_secret: your_client_secret
          fields: id,email,name,gender,picture
          # Original default Facebook scope was 'email,public_profile,user_friends'
          # Since March 2018 'user_friends' requires an app review.
          # Add the following three lines if you don't have it reviewed.
          query_params:
            authorize:
              scope: email,public_profile
        Google:
          tokens:
            client_id: your_client_id
            client_secret: your_client_secret
        AzureAD:
          tokens:
            client_id: your_client_id
            client_secret: your_client_secret
        Twitter:
          tokens:
            consumer_key: your_consumer_token
            consumer_secret: your_consumer_secret
        Github:
          tokens:
            client_id: your_client_id
            client_secret: your_client_secret
        Stackexchange:
          tokens:
            client_id: your_client_id
            client_secret: your_client_secret
            key: your_key
          site: stackoverflow
        Linkedin:
          tokens:
            client_id: your_client_id
            client_secret: your_client_secret
          fields: id,num-connections,picture-url,email-address
        VKontakte: # https://vk.com
          tokens:
            client_id: your_client_id
            client_secret: your_client_secret
          fields: 'first_name,last_name,about,bdate,city,country,photo_max_orig,sex,site'
          api_version: '5.8'
        Odnoklassniki: # https://ok.ru
          tokens:
            client_id: your_client_id
            client_secret: your_client_secret
            application_key: your_application_key
          method: 'users.getCurrentUser'
          format: 'json'
          fields: 'email,name,gender,birthday,location,uid,pic_full'
        MailRU:
          tokens:
            client_id: your_client_id
            client_private: your_client_private
            client_secret: your_client_secret
          method: 'users.getInfo'
          format: 'json'
          secure: 1
        Yandex:
          tokens:
            client_id: your_client_id
            client_secret: your_client_secret
          format: 'json'
        SalesForce:
          tokens:
            client_id: your_client_id
            client_secret: your_client_secret

[*] default value, may be omitted.


=head2 FUNCTIONAL LOGIN

The main purpose of this module is simply to authenticate against a third
party Identity Provider (IdP).

However you can get a bit more than that.

Your Dancer2 app might additionally use the "id_token" to access the API of
the same (or other) third parties to enable you to do cool stuff with your
apps, like show a feed, access data, etc.

Because access to the third party systems would be cut off when the "id_token"
expires, Dancer2::Plugin::Auth::OAuth will automatically set up the route
C</auth/$provider/refresh>. Call this when the token has expired to try to
refresh the token without bumping the user back to log in. You can optionally
tell Dancer2::Plugin::Auth::OAuth to bump the user back to the login page if
for whatever reason the refresh fails.

In addition, Dancer2::Plugin::Auth::OAuth will save or generate an auth session
key called "expires", which is (usually) number of seconds from epoch. Check
this to determine if the "id_token" has expired (see examples below).

Authenticate using one of the examples below but be sure to use the
'refresh' functionality, as the logged in user will need to have a
valid "id_token" at all times.

Also make sure that you set the scope of your authentication to tell the third
party what you wish to access (and for Microsoft/Azure also set the resource,
for the same reason).

Once you've got an active session you can get the "id_token" to use in further
calls to the providers backend systems with:

  my $session_data = session->read('oauth');
  my $token = $session_data->{$provider}{id_token};

=head1 SETTING THE SCOPE

If you're authenticating in order to use the "id_token" issued, or if login
requires a specific 'scope' setting, you can change these values in the initial
calls like this within your YAML config (example provided for AzureAD plugin).

  Auth::OAuth:
    providers:
      AzureAD:
        query_params:
          authorize:
            scope: 'Calendars.ReadWrite Contacts.Read Directory.Read.All Files.Read.All Group.Read.All GroupMember.Read.All Mail.ReadWrite openid People.Read Sites.Read.All Sites.ReadWrite.All User.Read User.ReadBasic.All Files.Read.All'

You do not need to list all other authorize attributes sent to the server,
unless you want to change them from the default values set in the provider.
Please view the provider source/documentation for what these default values are.

You may also need to set a value for "resource" in the same way. Refer to your
providers OAuth documentation.

=head1 AUTHENTICATION EXAMPLES

The response from the IdP is stored as a hash in the session with key "oauth".
An example of a Facebook response:

    {
        facebook   {
            access_token   "...",
            expires        1662472004,
            expires_in     5183933,
            issued_at      1657288071,
            token_type     "bearer",
            user_info      {
                email                "someone@example.com",
                id                   12345678901234567,
                name                 "José do Telhado",
                picture              {
                    data   {
                        height          50,
                        is_silhouette   0,
                        url             "https://platform-lookaside.fbsbx.com/platform/profilepic/...",
                        width           50
                    }
                },
            }
        }
    }

=over

=item Full site needs a user authentication for a specific IdP.

An example of a simple single system authentication.

    hook before => sub {
        my $session_data = session->read('oauth');
        my $provider = "facebook"; # Lower case of the authentication plugin used

        if ((!defined $session_data || !defined $session_data->{$provider} || !defined $session_data->{$provider}{id_token}) && request->path !~ m{^/auth}) {
          return forward "/auth/$provider";
        }
    };

If you want to be sure they have a valid "id_token" at all times:

    hook before => sub {
        my $session_data = session->read('oauth');
        my $provider = "facebook"; # Lower case of the authentication plugin used

        my $now = DateTime->now->epoch;

        if ((!defined $session_data || !defined $session_data->{$provider} || !defined $session_data->{$provider}{id_token}) && request->path !~ m{^/auth}) {
          return forward '/auth/$provider';

        } elsif (defined $session_data->{$provider}{refresh_token} && defined $session_data->{$provider}{expires} && $session_data->{$provider}{expires} < $now && request->path !~ m{^/auth}) {
          return forward "/auth/$provider/refresh";

        }
    };

in the case where you're using the refresh functionality, a failure of the
refresh will send the user back to the "error_url". If you want to them
to instead be directed back to the main authentication (log in page) then
please set the configuration option C<reauth_on_refresh_fail>.

If the provider(s) you are using don't have the "id_token"
change the example accordingly.

=item Site has a mix of public zones and private or needing use authentication

1. You only use one provider

    get '/we/need/a/user/here' => sub {
        my $session_data = session->read('oauth');
        my $provider = "facebook";

        redirect '/auth/$provider' unless $session_data && defined $session_data->{$provider};

        ...
    }



2. You also have a login page to choose from a list of
providers accepted by the site

You may update the configuration file:

    "Auth::OAuth":
        success_url: /login/ok
        error_url: /login/fail

And on your code

    get '/we/need/a/user/here' => sub {
        my $session_data = session->read('oauth');

        redirect '/login' unless $session_data;

        ...
    }

    get '/login/ok' => sub {
        my $session_data = session->read('oauth');

        redirect '/login' unless $session_data;

        # Do something with the user data, update DB,
        # update session, etc

    }

The login page can just have a list of the providers with
a link to "/auth/<lc-name-of-the-provider>"

You can mix this plugin with C<Dancer2::Plugin::Auth::Tiny> and
on '/login/ok' you just define the 'user' session. Afterwards
all validation can be against 'user' and not 'oauth'.

=back

=head1 AUTHOR

Menno Blom E<lt>blom@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2014- Menno Blom

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
