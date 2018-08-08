package Dancer::Plugin::Auth::Twitter;
BEGIN {
  $Dancer::Plugin::Auth::Twitter::AUTHORITY = 'cpan:SUKRIA';
}
#ABSTRACT: Authenticate with Twitter
$Dancer::Plugin::Auth::Twitter::VERSION = '0.08';
use strict;
use warnings;

use Dancer ':syntax';
use Dancer::Plugin;
use Carp 'croak';
use Twitter::API 1.0002;

# Net::Twitter singleton, accessible via 'twitter'
our $_twitter;
sub twitter { $_twitter }
register 'twitter' => \&twitter;

# init method, to create the Net::Twitter object
my $consumer_key;
my $consumer_secret;
my $callback_url;
my $callback_success;
my $callback_fail;

register 'auth_twitter_init' => sub {
    my $config = plugin_setting;

    $consumer_secret = $config->{consumer_secret};
    $consumer_key    = $config->{consumer_key};
    $callback_url    = $config->{callback_url};

    $callback_success = $config->{callback_success} || '/';
    $callback_fail    = $config->{callback_fail}    || '/fail';

    for my $param (qw/consumer_key consumer_secret callback_url/) {
        croak "'$param' is expected but not found in configuration" 
            unless $config->{$param};
    }

    debug "new twitter with $consumer_key , $consumer_secret, $callback_url";

    $_twitter = Twitter::API->new_with_traits(
        traits => [ qw/Enchilada/ ],
        'consumer_key'      => $consumer_key,
        'consumer_secret'   => $consumer_secret,
    );

};

# define a route handler that bounces to the OAuth authorization process
register 'auth_twitter_authorize_url' => sub {
    if (not defined twitter) {
        croak "auth_twitter_init must be called first";
    }

    my $oauth_tokens = twitter->oauth_request_token({
        callback => $callback_url
    });

    my $uri = twitter->oauth_authorization_url({
        oauth_token => $oauth_tokens->{oauth_token}
    });

    session request_token        => $oauth_tokens->{oauth_token};
    session request_token_secret => $oauth_tokens->{oauth_token_secret};

    debug "auth URL : $uri";
    return $uri;
};

# define a route handler that bounces to the OAuth authentication process
register 'auth_twitter_authenticate_url' => sub {
    if (not defined twitter) {
        croak "auth_twitter_init must be called first";
    }

    my $oauth_tokens = twitter->oauth_request_token({
        callback => $callback_url
    });

    my $uri = twitter->oauth_authentication_url({
        oauth_token => $oauth_tokens->{oauth_token}
    });

    session request_token        => $oauth_tokens->{oauth_token};
    session request_token_secret => $oauth_tokens->{oauth_token_secret};

    debug "auth URL : $uri";
    return $uri;
};

get '/auth/twitter/callback' => sub {
    my $token        = session('request_token');
    my $token_secret = session('request_token_secret');
    my $verifier     = params->{'oauth_verifier'};
    my $denied       = params->{'denied'};

    if (!$denied && $token && $token_secret && $verifier) {
        # everything went well:
        my $access = twitter->oauth_access_token({
            token        => $token,
            token_secret => $token_secret,
            verifier     => $verifier,
        });
        my $twitter_user_hash;
        my $success = eval {
            $twitter_user_hash = twitter->verify_credentials({
                -token        => $access->{oauth_token},
                -token_secret => $access->{oauth_token_secret},
            });
            1;
        };
        if (!$success || !$twitter_user_hash) {
            Dancer::Logger::core("no twitter_user_hash or error: $@");
            return redirect $callback_fail;
        }
        $twitter_user_hash->{'access_token'} = $access->{oauth_token},
            unless exists $twitter_user_hash->{'access_token'};
        $twitter_user_hash->{'access_token_secret'} = $access->{oauth_token_secret}
            unless exists $twitter_user_hash->{'access_token_secret'};

        # save the user
        session 'twitter_user' => $twitter_user_hash;
        return redirect $callback_success;
    }
    else {
        # user did NOT authenticate/authorize:
        session request_token        => '';
        session request_token_secret => '';
        return redirect $callback_fail if $denied; # user denied access
        return send_error 'no request token present, or no verifier';
    }
};

register_plugin;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer::Plugin::Auth::Twitter - Authenticate with Twitter

=head1 VERSION

version 0.07

=head1 SYNOPSIS

    package SomeDancerApp;
    use Dancer ':syntax';
    use Dancer::Plugin::Auth::Twitter;

    auth_twitter_init();

    before sub {
        if (not session('twitter_user')) {
            redirect auth_twitter_authenticate_url;
        }
    };

    get '/' => sub {
        "welcome, ".session('twitter_user')->{'screen_name'};
    };

    get '/fail' => sub { "FAIL" };

    ...

=head1 CONCEPT

This plugin provides a simple way to authenticate your users through Twitter's
OAuth API. It provides you with a helper to build easily a redirect to the
authentication URI, defines automatically a callback route handler and saves the
authenticated user to your session when done.

=head1 PREREQUESITES

In order for this plugin to work, you need the following:

=over 4 

=item * Twitter application

Anyone can register a Twitter application at L<http://developer.twitter.com/>. When
done, make sure to configure the application as a I<Web> application.

=item * Configuration

You need to configure the plugin first: copy your C<consumer_key> and C<consumer_secret> 
(provided by Twitter) to your Dancer's configuration under
C<plugins/Auth::Twitter>:

    # config.yml
    ...
    plugins:
      "Auth::Twitter":
        consumer_key:     "insert your comsumer key here"
        consumer_secret:  "insert your consumer secret here"
        callback_url:     "http://localhost:3000/auth/twitter/callback"
        callback_success: "/"
        callback_fail:    "/fail"

C<callback_url> is the URL in your app that Twitter will call after
authentication. Unless you really know what you're doing, it should B<always>
be C<your app url + /auth/twitter/callback>, like the example above. This
route is implemented by this plugin to properly handle the necessary OAuth
final steps and log your user.

C<callback_success> and C<callback_fail> are optional and default to 
'/' and '/fail', respectively. Once the callback_url processes the
authentication/authorization returned by Twitter, it will redirect the user
to those routes.

Before version 0.08, this module allowed the use of either C<Net::Twitter> or
C<Net::Twitter::Lite> as backend engines. Those modules have been merged into
the modern and up to date L<Twitter::API>, by the same author. Because Twitter
no longer supports the methods used in those modules, this plugin was updated
to use C<Twitter::API> as well.


=item * Session backend

For the authentication process to work, you need a session backend, in order for
the plugin to store the authenticated user's information.

Use the session backend of your choice, it doesn't make a difference, see
L<Dancer::Session> for details about supported session engines, or
L<search the CPAN for new ones|http://search.cpan.org/search?query=Dancer-Session>.

However, please note that the user access token will be stored on the session,
and that token may be used to query extra information from Twitter on behalf
of your users! As such, please keep your user's privacy in mind and
encrypt+secure your session data.

=back

=head1 EXPORT

The plugin exports the following symbols to your application's namespace:

=head2 twitter

The plugin uses a L<Twitter::API> object to do its job. You can access this
object with the C<twitter> symbol, exported by the plugin.

=head2 auth_twitter_init

This function should be called before your route handlers, in order to
initialize the underlying L<Twitter::API> object.

=head2 auth_twitter_authorize_url

This function returns an authorization URI to redirect unauthenticated users.
You should use this in a before filter like the following:

    before sub {
        # we don't want to bounce for ever!
        return if request->path =~ m{/auth/twitter/callback};
    
        if (not session('twitter_user')) {
            redirect auth_twitter_authorize_url();
        }
    };

When the user authenticates with Twitter's OAuth interface, she's going to be
bounced back to C</auth/twitter/callback>.

=head2 auth_twitter_authenticate_url

Similar to auth_twitter_authorize_url, but this function instead returns an
authenticate instead of authorize URI for redirecting unauthenticated users,
which results in a slightly different behaviour.

See L<https://dev.twitter.com/pages/sign_in_with_twitter|here> to learn about
the differences.

=head1 ROUTE HANDLERS

The plugin defines the following route handler automatically

=head2 /auth/twitter/callback

This route handler is responsible for catching back a user that has just
authenticated herself with Twitter's OAuth. The route handler saves tokens and
user information in the session and then redirects the user to the URI
specified by C<callback_success>.  

If the validation of the token returned by Twitter failed or was denied,
the user will be redirect to the URI specified by C<callback_fail>.

=head1 TIPS AND TRICKS

You should probably wrap your calls to C<auth_twitter_authorize_url> and
C<auth_twitter_authenticate_url> under C<eval>, as they make requests to
the Twitter API and may fail.

=head1 ACKNOWLEDGEMENTS

This plugin has been written as a port of
L<Catalyst::Authentication::Credential::Twitter> written by 
Jesse Stay.

This plugin was part of the Perl Dancer Advent Calendar 2010.

=head1 AUTHORS

=over 4

=item *

Alexis Sukrieh <sukria@sukria.net>

=item *

Dancer Core Developers

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010-18 by Alexis Sukrieh.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
