package CGI::Application::Plugin::Session;
{
  $CGI::Application::Plugin::Session::VERSION = '1.05';
}

use CGI::Session ();
use File::Spec ();
use CGI::Application 3.21;
use Carp qw(croak);
use Scalar::Util ();

# ABSTRACT: Plugin that adds session support to CGI::Application

use strict;
use vars qw($VERSION @EXPORT);

require Exporter;

@EXPORT = qw(
  session
  session_config
  session_cookie
  session_delete
  session_loaded
  session_recreate
);
sub import { goto &Exporter::import }

sub session {
    my $self = shift;

    if (!$self->{__CAP__SESSION_OBJ}) {
        # define the config hash if it doesn't exist to save some checks later
        $self->{__CAP__SESSION_CONFIG} = {} unless $self->{__CAP__SESSION_CONFIG};

        # gather parameters for the CGI::Session module from the user,
        #  or use some sane defaults
        my @params = ($self->{__CAP__SESSION_CONFIG}->{CGI_SESSION_OPTIONS}) ?
                        @{ $self->{__CAP__SESSION_CONFIG}->{CGI_SESSION_OPTIONS} } :
                        ('driver:File', $self->query, {Directory=>File::Spec->tmpdir});


        # CGI::Session only works properly with CGI.pm so extract the sid manually if
        # another module is being used
        if (Scalar::Util::blessed($params[1]) && ! $params[1]->isa('CGI')) {
            my $name = __locate_session_name( $self ); ## plugin method call
+           my $sid  = $params[1]->cookie($name) || $params[1]->param($name);
            $params[1] = $sid;
        }

        # create CGI::Session object or die with an error
        $self->{__CAP__SESSION_OBJ} = CGI::Session->new(@params);
        if (! $self->{__CAP__SESSION_OBJ} ) {
            my $errstr = CGI::Session->errstr || 'Unknown';
            croak "Failed to Create CGI::Session object :: Reason: $errstr";
        }

        # Set the default expiry if requested and if this is a new session
        if ($self->{__CAP__SESSION_CONFIG}->{DEFAULT_EXPIRY} && $self->{__CAP__SESSION_OBJ}->is_new) {
            $self->{__CAP__SESSION_OBJ}->expire($self->{__CAP__SESSION_CONFIG}->{DEFAULT_EXPIRY});
        }

        # add the cookie to the outgoing headers under the following conditions
        #  if the cookie doesn't exist,
        #  or if the session ID doesn't match what is in the current cookie,
        #  or if the session has an expiry set on it
        #  but don't send it if SEND_COOKIE is set to 0
        if (!defined $self->{__CAP__SESSION_CONFIG}->{SEND_COOKIE} || $self->{__CAP__SESSION_CONFIG}->{SEND_COOKIE}) {
            my $cid = $self->query->cookie(
                $self->{__CAP__SESSION_OBJ}->name
            );
            if (!$cid || $cid ne $self->{__CAP__SESSION_OBJ}->id || $self->{__CAP__SESSION_OBJ}->expire()) {
                session_cookie($self);
            }
        }
    }

    return $self->{__CAP__SESSION_OBJ};
}

sub session_config {
    my $self = shift;

    if (@_) {
      die "Calling session_config after the session has already been created" if (defined $self->{__CAP__SESSION_OBJ});
      my $props;
      if (ref($_[0]) eq 'HASH') {
          $props = $self->_cap_hash($_[0]);
      } else {
          $props = $self->_cap_hash({ @_ });
      }

      # Check for CGI_SESSION_OPTIONS
      if ($props->{CGI_SESSION_OPTIONS}) {
        die "session_config error:  parameter CGI_SESSION_OPTIONS is not an array reference" if ref $props->{CGI_SESSION_OPTIONS} ne 'ARRAY';
        $self->{__CAP__SESSION_CONFIG}->{CGI_SESSION_OPTIONS} = delete $props->{CGI_SESSION_OPTIONS};
      }

      # Check for COOKIE_PARAMS
      if ($props->{COOKIE_PARAMS}) {
        die "session_config error:  parameter COOKIE_PARAMS is not a hash reference" if ref $props->{COOKIE_PARAMS} ne 'HASH';
        $self->{__CAP__SESSION_CONFIG}->{COOKIE_PARAMS} = delete $props->{COOKIE_PARAMS};
      }

      # Check for SEND_COOKIE
      if (defined $props->{SEND_COOKIE}) {
        $self->{__CAP__SESSION_CONFIG}->{SEND_COOKIE} = (delete $props->{SEND_COOKIE}) ? 1 : 0;
      }

      # Check for DEFAULT_EXPIRY
      if (defined $props->{DEFAULT_EXPIRY}) {
        $self->{__CAP__SESSION_CONFIG}->{DEFAULT_EXPIRY} = delete $props->{DEFAULT_EXPIRY};
      }

      # If there are still entries left in $props then they are invalid
      die "Invalid option(s) (".join(', ', keys %$props).") passed to session_config" if %$props;
    }

    $self->{__CAP__SESSION_CONFIG};
}

sub session_cookie {
    my $self = shift;
    my %options = @_;

    # merge in any parameters set by config_session
    if ($self->{__CAP__SESSION_CONFIG}->{COOKIE_PARAMS}) {
      %options = (%{ $self->{__CAP__SESSION_CONFIG}->{COOKIE_PARAMS} }, %options);
    }

    if (!$self->{__CAP__SESSION_OBJ}) {
        # The session object has not been created yet, so make sure we at least call it once
        my $tmp = $self->session;
    }

    ## check cookie option -name with session name
    ## if different these may cause problems/confusion
    if ( exists $options{'-name'} and
        $options{'-name'} ne $self->session->name ) {
        warn sprintf( "Cookie '%s' and Session '%s' name don't match.\n",
            $options{'-name'}, $self->session->name )
    }

    ## setup the values for cookie
    $options{'-name'}    ||= $self->session->name;
    $options{'-value'}   ||= $self->session->id;
    if(defined($self->session->expires()) && !defined($options{'-expires'})) {
        $options{'-expires'} = _build_exp_time( $self->session->expires() );
    }
    my $cookie = $self->query->cookie(%options);

    # Look for a cookie header in the existing headers
    my %headers = $self->header_props;
    my $cookie_set = 0;
    if (my $cookies = $headers{'-cookie'}) {
        if (ref($cookies) eq 'ARRAY') {
            # multiple cookie headers so check them all
            for (my $i=0; $i < @$cookies; $i++) {
                # replace the cookie inline if we find a match
                if (substr($cookies->[$i], 0, length($options{'-name'})) eq $options{'-name'}) {
                    $cookies->[$i] = $cookie;
                    $cookie_set++;
                }
            }
        } elsif (substr($cookies, 0, length($options{'-name'})) eq $options{'-name'}) {
            # only one cookie and it is ours, so overwrite it
            $self->header_add(-cookie => $cookie);
            $cookie_set++;
        }
    }

    $self->header_add(-cookie => [$cookie]) unless $cookie_set;

    return 1;
}

sub _build_exp_time {
    my $secs_until_expiry = shift;
    return unless defined $secs_until_expiry;

    # Add a plus sign unless the number is negative
    my $prefix = ($secs_until_expiry >= 0) ? '+' : '';

    # Add an 's' for "seconds".
    return $prefix.$secs_until_expiry.'s';
}

sub session_delete {
    my $self = shift;

    if ( my $session = $self->session ) {
        $session->delete;
        $session->flush;
        if ( $self->{'__CAP__SESSION_CONFIG'}->{'SEND_COOKIE'} ) {
            my %options;
            if ( $self->{'__CAP__SESSION_CONFIG'}->{'COOKIE_PARAMS'} ) {
                %options = ( %{ $self->{'__CAP__SESSION_CONFIG'}->{'COOKIE_PARAMS'} }, %options );
            }
            $options{'name'} ||= $session->name;
            $options{'value'}    = '';
            $options{'-expires'} = '-1d';
            my $newcookie = $self->query->cookie(\%options);

            # See if a session cookie has already been set (this will happen if
            #  this is a new session).  We keep all existing cookies except the
            #  session cookie, which we replace with the timed out session
            #  cookie
            my @keep;
            my %headers = $self->header_props;
            my $cookies = $headers{'-cookie'} || [];
            $cookies = [$cookies] unless ref $cookies eq 'ARRAY';
            foreach my $cookie (@$cookies) {
                if ( ref($cookie) ne 'CGI::Cookie' || $cookie->name ne $session->name ) {
                    # keep this cookie
                    push @keep, $cookie;
                }
            }
            push @keep, $newcookie;

            # We have to set the cookies this way, because CGI::Application has
            #  an annoying interface to the headers (why can't we have
            #  'header_set as well as header_add?).  The first call replaces all
            #  cookie headers with the one new cookie header, and the next call
            #  adds in the rest of the cookies if there are any.
            $self->header_add( -cookie => shift @keep );
            $self->header_add( -cookie => \@keep ) if @keep;
        }
    }
}

sub session_loaded {
    my $self = shift;
    return defined $self->{__CAP__SESSION_OBJ};
}

sub session_recreate {
    my $self = shift;
    my $data = {};

    # Copy all values from existing session and delete it
    if (session_loaded($self)) {
        $data = $self->session->param_hashref;
        $self->session->delete;
        $self->session->flush;
        $self->{__CAP__SESSION_OBJ} = undef;

    }

    # create a new session and populate it
    #  (This should also send out a new cookie if so configured)
    my $session = $self->session;
    while(my($k,$v) = each %$data) {
        next if index($k, '_SESSION_') == 0;
        $session->param($k => $v);
    }
    $session->flush;

    return 1;
}

## all a hack to adjust for problems with cgi::session and
## it not playing with non-CGI.pm objects
sub __locate_session_name {
    my $self = shift;
    my $sess_opts = $self->{__CAP__SESSION_CONFIG}->{CGI_SESSION_OPTIONS};

    ## search for 'name' cgi session option
    if ( $sess_opts and $sess_opts->[4]
         and ref $sess_opts->[4] eq 'HASH'
         and exists $sess_opts->[4]->{name} ) {
        return $sess_opts->[4]->{name};
    }

    return CGI::Session->name;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CGI::Application::Plugin::Session - Plugin that adds session support to CGI::Application

=head1 VERSION

version 1.05

=head1 SYNOPSIS

 use CGI::Application::Plugin::Session;

 my $language = $self->session->param('language');

=head1 DESCRIPTION

CGI::Application::Plugin::Session seamlessly adds session support to your L<CGI::Application>
modules by providing a L<CGI::Session> object that is accessible from anywhere in
the application.

Lazy loading is used to prevent expensive file system or database calls from being made if
the session is not needed during this request.  In other words, the Session object is not
created until it is actually needed.  Also, the Session object will act as a singleton
by always returning the same Session object for the duration of the request.

This module aims to be as simple and non obtrusive as possible.  By not requiring
any changes to the inheritance tree of your modules, it can be easily added to
existing applications.  Think of it as a plugin module that adds a couple of
new methods directly into the CGI::Application namespace simply by loading the module.

=head1 NAME

CGI::Application::Plugin::Session - Add CGI::Session support to CGI::Application

=head1 METHODS

=head2 session

This method will return the current L<CGI::Session> object.  The L<CGI::Session> object is created on
the first call to this method, and any subsequent calls will return the same object.  This effectively
creates a singleton session object for the duration of the request.  L<CGI::Session> will look for a cookie
or param containing the session ID, and create a new session if none is found.  If C<session_config>
has not been called before the first call to C<session>, then it will choose some sane defaults to
create the session object.

  # retrieve the session object
  my $session = $self->session;

  - or -

  # use the session object directly
  my $language = $self->session->param('language');

=head2 session_config

This method can be used to customize the functionality of the CGI::Application::Plugin::Session module.
Calling this method does not mean that a new session object will be immediately created.
The session object will not be created until the first call to $self->session.  This
'lazy loading' can prevent expensive file system or database calls from being made if
the session is not needed during this request.

The recommended place to call C<session_config> is in the C<cgiapp_init>
stage of L<CGI::Application>.  If this method is called after the session object
has already been accessed, then it will die with an error message.

If this method is not called at all then a reasonable set of defaults
will be used (the exact default values are defined below).

The following parameters are accepted:

=over 4

=item CGI_SESSION_OPTIONS

This allows you to customize how the L<CGI::Session> object is created by providing a list of
options that will be passed to the L<CGI::Session> constructor.  Please see the documentation
for L<CGI::Session> for the exact syntax of the parameters.

=item DEFAULT_EXPIRY

L<CGI::Session> Allows you to set an expiry time for the session.  You can set the
DEFAULT_EXPIRY option to have a default expiry time set for all newly created sessions.
It takes the same format as the $session->expiry method of L<CGI::Session> takes.
Note that it is only set for new session, not when a session is reloaded from the store.

=item COOKIE_PARAMS

This allows you to customize the options that are used when creating the session cookie.
For example you could provide an expiry time for the cookie by passing -expiry => '+24h'.
The -name and -value parameters for the cookie will be added automatically unless
you specifically override them by providing -name and/or -value parameters.
See the L<CGI::Cookie> docs for the exact syntax of the parameters.

NOTE: You can do the following to get both the cookie name and the internal name of the CGI::Session object to be changed:

  $self->session_config(
    CGI_SESSION_OPTIONS => [
      $driver,
      $self->query,
      \%driver_options,
      { name => 'new_cookie_name' } # change cookie and session name
    ]
  );

Also, if '-name' parameter and 'name' of session don't match a warning will
be emitted.

=item SEND_COOKIE

If set to a true value, the module will automatically add a cookie header to
the outgoing headers if a new session is created (Since the session module is
lazy loaded, this will only happen if you make a call to $self->session at some
point to create the session object).  This option defaults to true.  If it is
set to false, then no session cookies will be sent, which may be useful if you
prefer URL based sessions (it is up to you to pass the session ID in this
case).

=back

The following example shows what options are set by default (ie this is what you
would get if you do not call session_config).

 $self->session_config(
          CGI_SESSION_OPTIONS => [ "driver:File", $self->query, {Directory=>'/tmp'} ],
          COOKIE_PARAMS       => {
                                   -path  => '/',
                                 },
          SEND_COOKIE         => 1,
 );

Here is a more customized example that uses the PostgreSQL driver and sets an
expiry and domain on the cookie.

 $self->session_config(
          CGI_SESSION_OPTIONS => [ "driver:PostgreSQL;serializer:Storable", $self->query, {Handle=>$dbh} ],
          COOKIE_PARAMS       => {
                                   -domain  => 'mydomain.com',
                                   -expires => '+24h',
                                   -path    => '/',
                                   -secure  => 1,
                                 },
 );

=head2 session_cookie

This method will add a cookie to the outgoing headers containing
the session ID that was assigned by the CGI::Session module.

This method is called automatically the first time $self->session is accessed
if SEND_COOKIE was set true, which is the default, so it will most likely never
need to be called manually.

NOTE that if you do choose to call it manually that a session object will
automatically be created if it doesn't already exist.  This removes the lazy
loading benefits of the plugin where a session is only created/loaded when
it is required.

It could be useful if you want to force the cookie header to be
sent out even if the session is not used on this request, or if
you want to manage the headers yourself by turning SEND_COOKIE to
false.

  # Force the cookie header to be sent including some
  # custom cookie parameters
  $self->session_cookie(-secure => 1, -expires => '+1w');

=head2 session_loaded

This method will let you know if the session object has been loaded yet.  In
other words, it lets you know if $self->session has been called.

  sub cgiapp_postrun {
    my $self = shift;
    $self->session->flush if $self->session_loaded;;
  }

=head2 session_recreate

This method will delete the existing session, and create a brand new one for
you with a new session ID.  It copies over all existing parameters into the new
session.

This can be useful to protect against some login attacks when storing
authentication tokens in the session.  Very briefly, an attacker loads a page
on your site and creates a session, then tries to trick a victim into loading
this page with the same session ID (possibly by embedding it in a URL).  Then
if the victim follows the link and subsequently logs into their account, the
attacker will have a valid session ID where the session is now logged in, and
hence the attacker has access to the victims account.

  sub mylogin {
    my $self = shift;
    if ($newly_authenticated) {
        $self->session_recreate;
    }
  }

=head2 session_delete

This method will perform a more comprehensive clean-up of the session, calling both
the CGI::Session delete() method, but also deleting the cookie from the client, if
you are using cookies.

  sub logout {
    my $self = shift;
    $self->session_delete;
    # what now?  redirect user back to the homepage?
  }

=head1 EXAMPLE

In a CGI::Application module:

  # configure the session once during the init stage
  sub cgiapp_init {
    my $self = shift;

    # Configure the session
    $self->session_config(
       CGI_SESSION_OPTIONS => [ "driver:PostgreSQL;serializer:Storable", $self->query, {Handle=>$self->dbh} ],
       DEFAULT_EXPIRY      => '+1w',
       COOKIE_PARAMS       => {
                                -expires => '+24h',
                                -path    => '/',
                              },
       SEND_COOKIE         => 1,
    );

  }

  sub cgiapp_prerun {
    my $self = shift;

    # Redirect to login, if necessary
    unless ( $self->session->param('~logged-in') ) {
      $self->prerun_mode('login');
    }
  }

  sub my_runmode {
    my $self = shift;

    # Load the template
    my $template = $self->load_tmpl('my_runmode.tmpl');

    # Add all the session parameters to the template
    $template->param($self->session->param_hashref());

    # return the template output
    return $template->output;
  }

=head1 TODO

=over 4

=item *

I am considering adding support for other session modules in the future,
like L<Apache::Session> and possibly others if there is a demand.

=item *

Possibly add some tests to make sure cookies are accepted by the client.

=item *

Allow a callback to be executed right after a session has been created

=back

=head1 SEE ALSO

L<CGI::Application>, L<CGI::Session>, perl(1)

=head1 AUTHOR

Cees Hek <ceeshek@gmail.com>

=head1 LICENSE

Copyright (C) 2004, 2005 Cees Hek <ceeshek@gmail.com>

This library is free software. You can modify and or distribute it under the same terms as Perl itself.

=head1 AUTHOR

Cees Hek <ceeshek@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Cees Hek.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
