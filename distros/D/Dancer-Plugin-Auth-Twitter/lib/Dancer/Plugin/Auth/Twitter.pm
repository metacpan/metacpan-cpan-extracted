package Dancer::Plugin::Auth::Twitter;
BEGIN {
  $Dancer::Plugin::Auth::Twitter::AUTHORITY = 'cpan:SUKRIA';
}
#ABSTRACT: Authenticate with Twitter
$Dancer::Plugin::Auth::Twitter::VERSION = '0.07';
use strict;
use warnings;

use Dancer ':syntax';
use Dancer::Plugin;
use Carp 'croak';
use Class::Load qw/ load_class /;
use Net::Twitter::Lite::WithAPIv1_1 0.12006;

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

my $engine;

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

    $engine = $config->{engine} || 'Net::Twitter::Lite::WithAPIv1_1';

    $engine .= '::WithAPIv1_1' if $engine eq 'Net::Twitter::Lite';

    die "engine must be 'Net::Twitter' or 'Net::Twitter::Lite::WithAPIv1_1': '$engine' not supported\n"
        unless grep { $engine eq $_ } qw/ Net::Twitter Net::Twitter::Lite::WithAPIv1_1 /;

    $_twitter = load_class($engine)->new(
        ( traits => [ qw/ API::RESTv1_1 OAuth / ] ) x ( $engine eq 'Net::Twitter' ),
        'consumer_key'      => $consumer_key, 
        'consumer_secret'   => $consumer_secret,
         ssl                 => 1,
    );

};

# define a route handler that bounces to the OAuth authorization process
register 'auth_twitter_authorize_url' => sub {
    if (not defined twitter) {
        croak "auth_twitter_init must be called first";
    }

    my $uri = twitter->get_authorization_url( 
        'callback' => $callback_url
    );

    session request_token        => twitter->request_token;
    session request_token_secret => twitter->request_token_secret;
    session access_token         => '';
    session access_token_secret  => '';

    debug "auth URL : $uri";
    return $uri;
};

# define a route handler that bounces to the OAuth authentication process
register 'auth_twitter_authenticate_url' => sub {
    if (not defined twitter) {
        croak "auth_twitter_init must be called first";
    }

    my $uri = twitter->get_authentication_url(
        'callback' => $callback_url
    );

    session request_token        => twitter->request_token;
    session request_token_secret => twitter->request_token_secret;
    session access_token         => '';
    session access_token_secret  => '';

    debug "auth URL : $uri";
    return $uri;
};

get '/auth/twitter/callback' => sub {

    debug "in callback...";

    # A user denying access should be considered a failure
    return redirect $callback_fail if (params->{'denied'});

    if (   !session('request_token')
        || !session('request_token_secret')
        || !params->{'oauth_verifier'})
    {
        return send_error 'no request token present, or no verifier';
    }

    my $token               = session('request_token');
    my $token_secret        = session('request_token_secret');
    my $access_token        = session('access_token');
    my $access_token_secret = session('access_token_secret');
    my $verifier            = params->{'oauth_verifier'};

    if (!$access_token && !$access_token_secret) {
        twitter->request_token($token);
        twitter->request_token_secret($token_secret);
        ($access_token, $access_token_secret) = twitter->request_access_token('verifier' => $verifier);

        # this is in case we need to register the user after the oauth process
        session access_token        => $access_token;
        session access_token_secret => $access_token_secret;
    }

    # get the user
    twitter->access_token($access_token);
    twitter->access_token_secret($access_token_secret);

    my $twitter_user_hash;
    eval {
        $twitter_user_hash = twitter->verify_credentials();
    };

    if ($@ || !$twitter_user_hash) {
        Dancer::Logger::core("no twitter_user_hash or error: ".$@);
        return redirect $callback_fail;
    }

    $twitter_user_hash->{'access_token'} = $access_token;
    $twitter_user_hash->{'access_token_secret'} = $access_token_secret;

    # save the user
    session 'twitter_user'                => $twitter_user_hash;
    session 'twitter_access_token'        => $access_token,
    session 'twitter_access_token_secret' => $access_token_secret,

    redirect $callback_success;
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

Anyone can register a Twitter application at L<http://dev.twitter.com/>. When
done, make sure to configure the application as a I<Web> application.

=item * Configuration

You need to configure the plugin first: copy your C<consumer_key> and C<consumer_secret> 
(provided by Twitter) to your Dancer's configuration under
C<plugins/Auth::Twitter>:

    # config.yml
    ...
    plugins:
      "Auth::Twitter":
        consumer_key:     "1234"
        consumer_secret:  "abcd"
        callback_url:     "http://localhost:3000/auth/twitter/callback"
        callback_success: "/"
        callback_fail:    "/fail"
        engine:           Net::Twitter::Lite::WithAPIv1_1

C<callback_success> and C<callback_fail> are optional and default to 
'/' and '/fail', respectively.

The engine is optional as well. The supported engines are
C<Net::Twitter> and C<Net::Twitter::Lite::WithAPIv1_1> (C<Net::Twitter::Lite> can also 
be used as a synonym for the latter).
By default the plugin will use L<Net::Twitter::Lite::WithAPIv1_1>.

Note that you also need to provide your callback url, whose route handler is automatically
created by the plugin.

=item * Session backend

For the authentication process to work, you need a session backend, in order for
the plugin to store the authenticated user's information.

Use the session backend of your choice, it doesn't make a difference, see
L<Dancer::Session> for details about supported session engines, or
L<search the CPAN for new ones|http://search.cpan.org/search?query=Dancer-Session>.

=back

=head1 EXPORT

The plugin exports the following symbols to your application's namespace:

=head2 twitter

The plugin uses a L<Net::Twitter> or L<Net::Twitter::Lite::WithAPIv1_1> 
object to do its job. You can access this
object with the C<twitter> symbol, exported by the plugin.

=head2 auth_twitter_init

This function should be called before your route handlers, in order to
initialize the underlying L<Net::Twitter> or L<Net::Twitter::Lite::WithAPIv1_1> 
object. 

=head2 auth_twitter_authorize_url

This function returns an authorize URI for redirecting unauthenticated users.
You should use this in a before filter like the following:

    before sub {
        # we don't want to bounce for ever!
        return if request->path =~ m{/auth/twitter/callback};
    
        if (not session('twitter_user')) {
            redirect auth_twitter_authorize_url();
        }
    };

When the user authenticate with Twitter's OAuth interface, she's going to be
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

If you get the error

    Net::Twitter::Role::OAuth::get_authorization_url(): 
        GET https://api.twitter.com/oauth/request_token failed: 500 
        Can't verify SSL peers without knowing which Certificate Authorities to trust

you can silence it by setting the environment variable C<PERL_LWP_SSL_VERIFY_HOSTNAME> to C<0>.

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

This software is copyright (c) 2010 by Alexis Sukrieh.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
