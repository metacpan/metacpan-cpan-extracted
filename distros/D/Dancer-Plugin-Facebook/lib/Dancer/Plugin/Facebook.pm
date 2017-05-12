package Dancer::Plugin::Facebook;
{
  $Dancer::Plugin::Facebook::VERSION = '0.991';
}
# ABSTRACT: Manage Facebook interaction within Dancer applications

use Dancer qw{:syntax};
use Dancer::Hook;
use Dancer::Plugin;
use Facebook::Graph;
use Try::Tiny;


my (%config, $fb, $redirect);

sub _get_fb {
    debug "Getting fb object [", $fb // "undef", "]";

    # The first time out, turn our raw, local postback URL into a
    # fully qualified one (see _do_fb_postback for more explanation).
    if ($config{raw_postback}) {
        my $url = delete $config{raw_postback};
        # Place the postback url in $config for object instantiation
        $config{postback} = uri_for ($url);
        debug "Full postback URL is ", $config{postback};
    }

    # We use a before hook to clear a stale FB handle out, and just
    # use ||= to regenerate as necessary here.
    $fb ||= do {
        my %settings = %config;
        if (my $access_token = session->{auth}->{facebook}) {
            $settings{access_token} = $access_token;
        }
        debug "Creating Facebook::Graph object with settings ", \%settings;
        Facebook::Graph->new (%settings);
    };
}

sub _get_fb_redirect_url () {
    $redirect ||= do {
        my $settings = plugin_setting;
        debug "Settings are ", $settings;
        my @permissions = ref $settings->{permissions} eq "ARRAY" ? @{$settings->{permissions}} : ();
        _get_fb->authorize->extend_permissions (@permissions)->uri_as_string;
    };
}

sub _do_fb_redirect () {
    my $url = _get_fb_redirect_url;
    sub {
        debug "Redirecting to $url";
        redirect $url, 303;
    }
}

sub _do_fb_postback ($) {
    my $settings = plugin_setting;
    debug "Settings are ", $settings;

    my ($url) = @_;

    # We can only determine the relative URL right now, but that's
    # enough for initializing the route.  We put the relative URL
    # in $config{raw_postback} so that when fb is called for the
    # first time, which will be within a route handler, we can sub
    # in the full URL, which is what FB actually needs
    die "You must give me the postback URL when calling fb_postback" unless ($url);
    $config{raw_postback} = $url;

    # This hook will get called when we successfully authenticate and have
    # put the token in the session, so the application developer can
    # retrieve it.  It doesn't need to exist if a postback route hasn't been
    # established
    register_hook (['fb_access_token_available']);

    my $success = $settings->{landing}->{success} || "/";
    my $failure = $settings->{landing}->{failure} || "/";

    sub {
        try {
            my $token = _get_fb->request_access_token (params->{code});
            session->{auth}->{facebook} = $token->token;
            execute_hooks 'fb_access_token_available', $token->token;
            # Go back wherever
            redirect $success;
        } catch {
            redirect $failure;
        };
    }
}

register setup_fb => sub (;$) {
    my ($url) = @_;
    debug "Setting up fb access";

    # We need global access to this, grab it here
    my $settings = plugin_setting;
    debug "Settings are ", $settings;

    # Copy our registered application information over
    if (ref $settings->{application} eq "HASH") {
        debug "Setting application information";
        $config{app_id} = $settings->{application}->{app_id} or die "You didn't give me an app_id for Dancer::Plugin::Facebook";
        $config{secret} = $settings->{application}->{secret} or die "You didn't give me a secret for Dancer::Plugin::Facebook";
    }

    # Set a hook to clear out any old object unless existing tokens in
    # the object and session match one another.  In theory, this means
    # that absent an access token, we should never replace it.
    debug "Setting hook to clear facebook context";
    hook before => sub {
        if (defined $fb) {
            debug "Considering clearing facebook context";
            if (defined session->{auth}->{facebook}) {
                if ($fb->has_access_token) {
                    if ($fb->access_token ne session->{auth}->{facebook}) {
                        debug "Current FB access token doesn't match";
                        undef $fb;
                    }
                } else {
                    debug "Current FB doesn't have access token";
                    undef $fb;
                }
            } else {
                if ($fb->has_access_token) {
                    debug "Current login doesn't have access token";
                    undef $fb;
                }
            }
        }
    };

    # If the user wants the automatic URL setup
    if ($url) {
        debug "Creating handler for ", $url;
        get $url => _do_fb_redirect;

        my $postback = "$url/postback";
        debug "Creating handler for ", $postback;
        get $postback => _do_fb_postback $postback;
    }

    debug "Done setting up fb access";
};

register fb => \&_get_fb;
register fb_redirect => \&_do_fb_redirect;
register fb_redirect_url => \&_get_fb_redirect_url;
register fb_postback => \&_do_fb_postback;
register_plugin;


1;

__END__
=pod

=head1 NAME

Dancer::Plugin::Facebook - Manage Facebook interaction within Dancer applications

=head1 VERSION

version 0.991

=head1 SYNOPSIS

  use Dancer;
  use Dancer::Plugin::Facebook;

  setup_fb '/auth/facebook';

  get '/' => sub {
    fb->fetch ('16665510298')->{name};
  } # returns 'perl'

=head1 DESCRIPTION

C<Dancer::Plugin::Facebook> is intended to simplify using
C<Facebook::Graph> from within a Dancer application.

It will:

=over

=item manage the lifecycle of the Facebook::Graph object

The plugin goes to great lengths to only create the C<Facebook::Graph>
object when needed, and tries hard to cache it for as long as it it is
valid, so you can use the fb object repeatedly during a request, even
in different handlers, without it being rebuilt needlessly.

=item store your applications registration information in a single place

Though it's not required that you have an registered app, if you do,
you need only record the C<app_id> and C<secret> in one place.

=item automatically create routes for handling authentication

If you pass a path to the C<setup_fb> routine, the plugin will create
the routes necessary to support authentication in that location.

=item automatically manage user authentication tokens

It will transparently manage them through the user session for you,
collecting them when the user authenticates, and making sure that they
are used when creating the C<Facebook::Graph> object if they're present.

There is also a hook available (C<fb_access_token_available>) you can
use to retrieve and store the C<access_token> for offline use when it
is set.  Then, simply store the C<access_token> in
C<session->{auth}->{facebook}> and the C<fb> object will automatically
pick it up on each request.

=back

=head1 USAGE

=head2 Basic usage

At its absolute most basic usage, you can simply load the module into
your dancer application:

  use Dancer;
  use Dancer::Plugin::Facebook;

This will configure the absolute bare minimum functionality, allowing
you to make requests to Facebook's API for public information and
nothing else.

=head2 Registered application

If you have registered an application with Facebook, you will need to
configure the module to use the relevant C<app_id> and C<secret> (see
L<CONFIGURATION> for details), and you will need to call the setup_fb
routine:

  use Dancer;
  use Dancer::Plugin::Facebook;
  setup_fb;

In all other respects, the usage is the same as the basic usage.

=head2 Authenticating users (simple)

If you're using Facebook for authentication, you may specify a point
where the necessary web routes can be mounted when you call
C<setup_fb>, like so:

  use Dancer;
  use Dancer::Plugin::Facebook;
  setup_fb '/auth/facebook';

You should configure the module know where to redirect the user in the
event of success or failure by configuring the C<landing> parameters
(see L<CONFIGURATION> for details).

To authenticate a user, simply redirect them to C</auth/facebook>, and
when the user has been authenticated with Facebook, they will be
redirected to C<landing/success> (which is C</> by default).

=head2 Authenticating users (more configurable URLs)

If you absolutely need to set specific URLs for the redirection and
postback pages, you can do this by setting up the routes yourself.

Do not specify a URL when calling C<setup_fb>, and then use the
C<fb_redirect> and C<fb_postback> functions to create your routes:

  use Dancer;
  use Dancer::Plugin::Facebook;
  setup_fb;

  get '/a/complicated/facebook/redirect/url' => fb_redirect;
  get '/a/postback/url/in/a/totally/different/place' => fb_postback '/a/postback/url/in/a/totally/different/place';

Please note, you do need to specify the postback URL as a parameter to
C<fb_postback>.  It's ugly, but unavoidable as far as I can tell.

=head2 Authenticating users (handling redirection when using AJAX)

If you are using AJAX to interoperate with your application, returning
a 30X redirect code to push the user to Facebook may not work the way
you expect.  So, if necessary, you can just get back the appropriate
URL, and send that to your client in some way it will interpret
properly.

  use Dancer;
  use Dancer::Plugin::Facebook;

  setup_fb;

  post '/auth' => sub {
    ... do some stuff to decide if you are supposed to even hit fb ...
    # hypothetically encoded as JSON and parsed by client app
    return {redirect => fb_redirect_url};
  };

  get '/auth/facebook/postback' => fb_postback '/auth/facebook/postback';

Please note, you do need to specify the postback URL as a parameter to
C<fb_postback>.  It's ugly, but unavoidable as far as I can tell.

=head2 Acting on a user's behalf (while logged in)

If you wish for your application to be able to access Facebook on
behalf of a particular user while the user is logged in, you simply
need to additionally configure the permissions the application
requires (see L<CONFIGURATION> for details).

Then, when the user has authenticated (and accepted your request for
additional authorization), you may use the C<fb> function to get a
pre-configured C<Facebook::Graph> object that will allow appropriate
access:

  use Dancer;
  use Dancer::Plugin::Facebook;
  setup_fb '/auth/facebook';

  get '/userinfo' => sub {
    my $user = fb->fetch ('me');
  }

=head2 Acting on a user's behalf (offline)

If you wish for your application to be able to access Facebook on
behalf of a particular user while the user is offline, you will need
to additionally configure the permissions the application requires
(see L<CONFIGURATION> for details) to include C<offline_access>

Then, when the user has authenticated (and accepted your request for
additional authorization), you should make sure to store the
C<access_token> that the authentication process returned and place it
in stable storage for later use:

  use Dancer;
  use Dancer::Plugin::Facebook;
  setup_fb '/auth/facebook';

  hook fb_access_token_available => sub {
    my ($token) = @_;
    ... store $token to DB ---
  }

=head1 CONFIGURATION

Your L<Dancer> C<config.yml> file C<plugins> section should look
something like this.

  plugins:
    Facebook:
      application:
        app_id: XXXXXXXXXXXXXXX
        secret: XXXXXXXXXXXXXXX
      landing:
        failure: /error
        success: /
      permissions:
        - create_event
        - email
        - offline_access
        - publish_stream
        - rsvp_event

The C<app_id> and C<secret> keys in the C<application> section
correspond to the values available from L<the information page for your
application|https://developers.facebook.com/apps>.

The C<failure> and C<success> keys in the C<landing> section point to
the URL(s) to redirect to upon success or failure in authenticating.
If they're not present, they both default to C</>.

The C<permissions> key includes a list of additional permissions you
may request at the time the user authorizes your application.
Facebook maintains L<a full list of available extended
permissions|http://developers.facebook.com/docs/authentication/permissions>.

=head1 SEE ALSO

L<Dancer>

L<Facebook::Graph>

=head1 AUTHOR

Michael Alan Dorman <mdorman@ironicdesign.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Michael Alan Dorman.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

