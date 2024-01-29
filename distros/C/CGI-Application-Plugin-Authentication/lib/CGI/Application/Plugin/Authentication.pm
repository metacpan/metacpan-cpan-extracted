package CGI::Application::Plugin::Authentication;
$CGI::Application::Plugin::Authentication::VERSION = '0.24';
use 5.006;
use strict;

our %__CONFIG;

use Class::ISA ();
use Scalar::Util ();
use UNIVERSAL::require;
use Carp;
use CGI ();
use overload;

sub import {
    my $pkg     = shift;
    my $callpkg = caller;
    {
        no strict qw(refs);
        *{$callpkg.'::authen'} = \&CGI::Application::Plugin::_::Authentication::authen;
    }
    if ( ! UNIVERSAL::isa($callpkg, 'CGI::Application') ) {
        warn "Calling package is not a CGI::Application module so not setting up the prerun hook.  If you are using \@ISA instead of 'use base', make sure it is in a BEGIN { } block, and make sure these statements appear before the plugin is loaded";
    } else {
        $callpkg->add_callback( prerun => \&prerun_callback );
    }
}

use Attribute::Handlers;
my %RUNMODES;

sub CGI::Application::RequireAuthentication : ATTR(CODE) {
    my ( $package, $symbol, $referent, $attr, $data, $phase ) = @_;
    $RUNMODES{$referent} = $data || 1;
}
sub CGI::Application::Authen : ATTR(CODE) {
    my ( $package, $symbol, $referent, $attr, $data, $phase ) = @_;
    $RUNMODES{$referent} = $data || 1;
}


=head1 NAME

CGI::Application::Plugin::Authentication - Authentication framework for CGI::Application

=head1 SYNOPSIS

 package MyCGIApp;

 use base qw(CGI::Application); # make sure this occurs before you load the plugin

 use CGI::Application::Plugin::Authentication;

 MyCGIApp->authen->config(
       DRIVER => [ 'Generic', { user1 => '123' } ],
 );
 MyCGIApp->authen->protected_runmodes('myrunmode');

 sub myrunmode {
    my $self = shift;

    # The user should be logged in if we got here
    my $username = $self->authen->username;

 }

=head1 DESCRIPTION

CGI::Application::Plugin::Authentication adds the ability to authenticate users
in your L<CGI::Application> modules.  It imports one method called 'authen' into your
CGI::Application module.  Through the authen method you can call all the methods of
the CGI::Application::Plugin::Authentication plugin.

There are two main decisions that you need to make when using this module.  How will
the usernames and password be verified (i.e. from a database, LDAP, etc...), and how
can we keep the knowledge that a user has already logged in persistent, so that they
will not have to enter their credentials again on the next request (i.e. how do we 'Store'
the authentication information across requests).

=head2 Choosing a Driver

There are three drivers that are included with the distribution.  Also, there
is built in support for all of the Authen::Simple modules (search CPAN for
Authen::Simple for more information).  This should be enough to cover
everyone's needs.  

If you need to authenticate against a source that is not provided, you can use
the Generic driver which will accept either a hash of username/password pairs,
or an array of arrays of credentials, or a subroutine reference that can verify
the credentials.  So through the Generic driver you should be able to write
your own verification system.  There is also a Dummy driver, which blindly
accepts any credentials (useful for testing).  See the
L<CGI::Application::Plugin::Authentication::Driver::Generic>,
L<CGI::Application::Plugin::Authentication::Driver::DBI> and,
L<CGI::Application::Plugin::Authentication::Driver::Dummy> docs for more
information on how to use these drivers.  And see the L<Authen::Simple> suite
of modules for information on those drivers.

=head2 Choosing a Store

The Store modules keep information about the authentication status of the user persistent
across multiple requests.  The information that is stored in the store include the username,
and the expiry time of the login.  There are two Store modules included with this distribution.
A Session based store, and a Cookie based store.  If your application is already using
Sessions (through the L<CGI::Application::Plugin::Session> module), then I would recommend
that you use the Session store for authentication.  If you are not using the Session
plugin, then you can use the Cookie store.  The Cookie store keeps all the authentication
in a cookie, which contains a checksum to ensure that users can not change the information.

If you do not specify which Store module you wish to use, the plugin will try to determine
the best one for you.

=head2 Login page

The Authentication plugin comes with a default login page that can be used if you do not
want to create a custom login page.  This login form will automatically be used if you
do not provide either a LOGIN_URL or LOGIN_RUNMODE parameter in the configuration.
If you plan to create your own login page, I would recommend that you start with the HTML
code for the default login page, so that your login page will contain the correct form
fields and hidden fields.

=head2 Ticket based authentication

This Authentication plugin can handle ticket based authentication systems as well.  All that
is required of you is to write a Store module that can understand the contents of the ticket.
The Authentication plugin will require at least the 'username' to be retrieved from the
ticket.  A Ticket based authentication scheme will not need a Driver module at all, since the
actual verification of credentials is done by an external authentication system, possibly
even on a different host.  You will need to specify the location of the login page using
the LOGIN_URL configuration variable, and unauthenticated users will automatically
be redirected to your ticket authentication login page.


=head1 EXPORTED METHODS

=head2 authen

This is the only method exported from this module.  Everything is controlled
through this method call, which will return a CGI::Application::Plugin::Authentication
object, or just the class name if called as a class method.  When using
the plugin, you will always first call $self->authen or __PACKAGE__->authen and
then the method you wish to invoke.  For example:

  __PACKAGE__->authen->config(
        LOGIN_RUNMODE => 'login',
  );

- or -

  $self->authen->protected_runmodes(qw(one two));

=cut


{   package # Hide from PAUSE
        CGI::Application::Plugin::_::Authentication;

    ##############################################
    ###
    ###   authen
    ###
    ##############################################
    #
    # Return an authen object that can be used
    # for managing authentication.
    #
    # This will return a class name if called
    # as a class name, and a singleton object
    # if called as an object method
    #
    sub authen {
        my $cgiapp = shift;

        if (ref($cgiapp)) {
            return CGI::Application::Plugin::Authentication->instance($cgiapp);
        } else {
            return 'CGI::Application::Plugin::Authentication';
        }
    }

}

package CGI::Application::Plugin::Authentication;



=head1 METHODS

=head2 config

This method is used to configure the CGI::Application::Plugin::Authentication
module.  It can be called as an object method, or as a class method. Calling this function,
will not itself generate cookies or session ids.

The following parameters are accepted:

=over 4

=item DRIVER

Here you can choose which authentication module(s) you want to use to perform the authentication.
For simplicity, you can leave off the CGI::Application::Plugin::Authentication::Driver:: part
when specifying the DRIVER name  If this module requires extra parameters, you
can pass an array reference that contains as the first parameter the name of the module,
and the rest of the values in the array will be considered options for the driver.  You can provide
multiple drivers which will be used, in order, to check the credentials until
a valid response is received.

     DRIVER => 'Dummy' # let anyone in regardless of the password

  - or -

     DRIVER => [ 'DBI',
         DBH         => $self->dbh,
         TABLE       => 'user',
         CONSTRAINTS => {
             'user.name'         => '__CREDENTIAL_1__',
             'MD5:user.password' => '__CREDENTIAL_2__'
         },
     ],

  - or -

     DRIVER => [
         [ 'Generic', { user1 => '123' } ],
         [ 'Generic', sub { my ($u, $p) = @_; is_prime($p) ? 1 : 0 } ]
     ],

  - or -

     DRIVER => [ 'Authen::Simple::LDAP',
         host   => 'ldap.company.com',
         basedn => 'ou=People,dc=company,dc=net'
     ],


=item STORE

Here you can choose how we store the authenticated information after a user has successfully 
logged in.  We need to store the username so that on the next request we can tell the user
has already logged in, and we do not have to present them with another login form.  If you
do not provide the STORE option, then the plugin will look to see if you are using the
L<CGI::Application::Plugin::Session> module and based on that info use either the Session
module, or fall back on the Cookie module.  If the module requires extra parameters, you
can pass an array reference that contains as the first parameter the name of the module,
and the rest of the array should contain key value pairs of options for this module.
These storage modules generally live under the CGI::Application::Plugin::Authentication::Store::
name-space, and this part of the package name can be left off when specifying the STORE
parameter.

    STORE => 'Session'

  - or -

    STORE => ['Cookie',
        NAME   => 'MYAuthCookie',
        SECRET => 'FortyTwo',
        EXPIRY => '1d',
    ]


=item POST_LOGIN_RUNMODE

Here you can specify a runmode that the user will be redirected to if they successfully login.

  POST_LOGIN_RUNMODE => 'welcome'

=item POST_LOGIN_URL

Here you can specify a URL that the user will be redirected to if they successfully login.
If both POST_LOGIN_URL and POST_LOGIN_RUNMODE are specified, then the latter
will take precedence.

  POST_LOGIN_URL => 'http://example.com/start.cgi'

=item POST_LOGIN_CALLBACK

A code reference that is executed after login processing but before POST_LOGIN_RUNMODE or
redirecting to POST_LOGIN_URL. This is normally a method in your CGI::Application application
and as such the CGI::Application object is passed as a parameter. 

  POST_LOGIN_CALLBACK => \&update_login_date

and later in your code:

  sub update_login_date {
    my $self = shift;

    return unless($self->authen->is_authenticated);

    ...
  }


=item LOGIN_RUNMODE

Here you can specify a runmode that the user will be redirected to if they need to login.

  LOGIN_RUNMODE => 'login'

=item LOGIN_URL

If your login page is external to this module, then you can use this option to specify a
URL that the user will be redirected to when they need to login. If both
LOGIN_URL and LOGIN_RUNMODE are specified, then the latter will take precedence.

  LOGIN_URL => 'http://example.com/login.cgi'

=item LOGOUT_RUNMODE

Here you can specify a runmode that the user will be redirected to if they ask to logout.

  LOGOUT_RUNMODE => 'logout'

=item LOGOUT_URL

If your logout page is external to this module, then you can use this option to specify a
URL that the user will be redirected to when they ask to logout.  If both
LOGOUT_URL and LOGOUT_RUNMODE are specified, then the latter will take precedence.

  LOGIN_URL => 'http://example.com/logout.html'

=item DETAINT_URL_REGEXP

This is a regular expression used to detaint URLs used in the login form. By default it will be set to

  ^([\w\_\%\?\&\;\-\/\@\.\+\$\=\#\:\!\*\"\'\(\)\,]+)$

This regular expression is based upon the document http://www.w3.org/Addressing/URL/url-spec.txt. You could 
set it to a more specific regular expression to limit the domains to which users could be directed.

=item DETAINT_USERNAME_REGEXP

This is a regular expression used to detaint the username parameter used in the login form. By default it will be set to

  ^([\w\_]+)$

=item CREDENTIALS

Set this to the list of form fields where the user will type in their username and password.
By default this is set to ['authen_username', 'authen_password'].  The form field names should
be set to a value that you are not likely to use in any other forms.  This is important
because this plugin will automatically look for query parameters that match these values on
every request to see if a user is trying to log in.  So if you use the same parameter names
on a user management page, you may inadvertently perform a login when that was not intended.
Most of the Driver modules will return the first CREDENTIAL as the username, so make sure
that you list the username field first.  This option can be ignored if you use the built in
login box

  CREDENTIALS => 'authen_password'

  - or -

  CREDENTIALS => [ 'authen_username', 'authen_domain', 'authen_password' ]


=item LOGIN_SESSION_TIMEOUT


This option can be used to tell the system when to force the user to re-authenticate.  There are
a few different possibilities that can all be used concurrently:

=over 4

=item IDLE_FOR

If this value is set, a re-authentication will be forced if the user was idle for more then x amount of time.

=item EVERY

If this value is set, a re-authentication will be forced every x amount of time.

=item CUSTOM

This value can be set to a subroutine reference that returns true if the session should be timed out,
and false if it is still active.  This can allow you to be very selective about how the timeout system
works.  The authen object will be passed in as the only parameter.

=back

Time values are specified in seconds. You can also specify the time by using a number with the
following suffixes (m h d w), which represent minutes, hours, days and weeks.  The default
is 0 which means the login will never timeout.

Note that the login is also dependent on the type of STORE that is used.  If the Session store is used,
and the session expires, then the login will also automatically expire.  The same goes for the Cookie
store.

For backwards compatibility, if you set LOGIN_SESSION_TIMEOUT to a time value instead of a hashref,
it will be treated as an IDLE_FOR time out.

  # force re-authentication if idle for more than 15 minutes
  LOGIN_SESSION_TIMEOUT => '15m'

  # Everyone must re-authentication if idle for more than 30 minutes
  # also, everyone must re-authentication at least once a day
  # and root must re-authentication if idle for more than 5 minutes
  LOGIN_SESSION_TIMEOUT => {
        IDLE_FOR => '30m',
        EVERY    => '1d',
        CUSTOM   => sub {
          my $authen = shift;
          return ($authen->username eq 'root' && (time() - $authen->last_access) > 300) ? 1 : 0;
        }
  }

=item RENDER_LOGIN

This value can be set to a subroutine reference that returns the HTML of a login
form. The subroutine reference overrides the default call to login_box.
The subroutine is normally a method in your CGI::Application application and as such the 
CGI::Application object is passed as the first parameter. 

  RENDER_LOGIN => \&login_form

and later in your code:

  sub login_form {
    my $self = shift;

    ...
    return $html
  }

=item LOGIN_FORM

You can set this option to customize the login form that is created when a user
needs to be authenticated.  If you wish to replace the entire login form with a
completely custom version, then just set LOGIN_RUNMODE to point to your custom
runmode.

All of the parameters listed below are optional, and a reasonable default will
be used if left blank:

=over 4

=item DISPLAY_CLASS (default: Classic)

the class used to display the login form. The alternative is C<Basic>
which aims for XHTML compliance and leaving style to CSS. See
L<CGI::Application::Plugin::Authentication::Display> for more details.

=item TITLE (default: Sign In)

the heading at the top of the login box 

=item USERNAME_LABEL (default: User Name)

the label for the user name input

=item PASSWORD_LABEL (default: Password)

the label for the password input

=item SUBMIT_LABEL (default: Sign In)

the label for the submit button

=item COMMENT (default: Please enter your username and password in the fields below.)

a message provided on the first login attempt

=item REMEMBERUSER_OPTION (default: 1)

provide a checkbox to offer to remember the users name in a cookie so that
their user name will be pre-filled the next time they log in

=item REMEMBERUSER_LABEL (default: Remember User Name)

the label for the remember user name checkbox

=item REMEMBERUSER_COOKIENAME (default: CAPAUTHTOKEN)

the name of the cookie where the user name will be saved

=item REGISTER_URL (default: <none>)

the URL for the register new account link

=item REGISTER_LABEL (default: Register Now!)

the label for the register new account link

=item FORGOTPASSWORD_URL (default: <none>)

the URL for the forgot password link

=item FORGOTPASSWORD_LABEL (default: Forgot Password?)

the label for the forgot password link

=item INVALIDPASSWORD_MESSAGE (default: Invalid username or password<br />(login attempt %d)

a message given when a login failed

=item INCLUDE_STYLESHEET (default: 1)

use this to disable the built in style-sheet for the login box so you can provide your own custom styles

=item FORM_SUBMIT_METHOD (default: post)

use this to get the form to submit using 'get' instead of 'post'

=item FOCUS_FORM_ONLOAD (default: 1)

use this to automatically focus the login form when the page loads so a user can start typing right away.

=item BASE_COLOUR (default: #445588)

This is the base colour that will be used in the included login box.  All other
colours are automatically calculated based on this colour (unless you hardcode
the colour values).  In order to calculate other colours, you will need the
Color::Calc module.  If you do not have the Color::Calc module, then you will
need to use fixed values for all of the colour options.  All colour values
besides the BASE_COLOUR can be simple percentage values (including the % sign).
For example if you set the LIGHTER_COLOUR option to 80%, then the calculated
colour will be 80% lighter than the BASE_COLOUR.

=item LIGHT_COLOUR (default: 50% or #a2aac4)

A colour that is lighter than the base colour.

=item LIGHTER_COLOUR (default: 75% or #d0d5e1)

A colour that is another step lighter than the light colour.

=item DARK_COLOUR (default: 30% or #303c5f)

A colour that is darker than the base colour.

=item DARKER_COLOUR (default: 60% or #1b2236)

A colour that is another step darker than the dark colour.

=item GREY_COLOUR (default: #565656)

A grey colour that is calculated by desaturating the base colour.

=back

=back

=cut

sub config {
    my $self  = shift;
    my $class = ref $self ? ref $self : $self;

    die "Calling config after the Authentication object has already been initialized"
        if ref $self && defined $self->{initialized};
    my $config = $self->_config;

    if (@_) {
        my $props;
        if ( ref( $_[0] ) eq 'HASH' ) {
            my $rthash = %{ $_[0] };
            $props = CGI::Application->_cap_hash( $_[0] );
        } else {
            $props = CGI::Application->_cap_hash( {@_} );
        }

        # Check for DRIVER
        if ( defined $props->{DRIVER} ) {
            croak "authen config error:  parameter DRIVER is not a string or arrayref"
              if ref $props->{DRIVER} && Scalar::Util::reftype( $props->{DRIVER} ) ne 'ARRAY';
            $config->{DRIVER} = delete $props->{DRIVER};
            # We will accept a string, or an arrayref of options, but what we really want
            # is an array of arrayrefs of options, so that we can support multiple drivers
            # each with their own custom options
            no warnings qw(uninitialized);
            $config->{DRIVER} = [ $config->{DRIVER} ] if Scalar::Util::reftype( $config->{DRIVER} ) ne 'ARRAY';
            $config->{DRIVER} = [ $config->{DRIVER} ] if Scalar::Util::reftype( $config->{DRIVER}->[0] ) ne 'ARRAY';
        }

        # Check for STORE
        if ( defined $props->{STORE} ) {
            croak "authen config error:  parameter STORE is not a string or arrayref"
              if ref $props->{STORE} && Scalar::Util::reftype( $props->{STORE} ) ne 'ARRAY';
            $config->{STORE} = delete $props->{STORE};
            # We will accept a string, but what we really want is an arrayref of the store driver,
            # and any custom options
            no warnings qw(uninitialized);
            $config->{STORE} = [ $config->{STORE} ] if Scalar::Util::reftype( $config->{STORE} ) ne 'ARRAY';
        }

        # Check for POST_LOGIN_RUNMODE
        if ( defined $props->{POST_LOGIN_RUNMODE} ) {
            croak "authen config error:  parameter POST_LOGIN_RUNMODE is not a string"
              if ref $props->{POST_LOGIN_RUNMODE};
            $config->{POST_LOGIN_RUNMODE} = delete $props->{POST_LOGIN_RUNMODE};
        }

        # Check for POST_LOGIN_URL
        if ( defined $props->{POST_LOGIN_URL} ) {
            carp "authen config warning:  parameter POST_LOGIN_URL ignored since we already have POST_LOGIN_RUNMODE"
              if $config->{POST_LOGIN_RUNMODE};
            croak "authen config error:  parameter POST_LOGIN_URL is not a string"
              if ref $props->{POST_LOGIN_URL};
            $config->{POST_LOGIN_URL} = delete $props->{POST_LOGIN_URL};
        }

        # Check for LOGIN_RUNMODE
        if ( defined $props->{LOGIN_RUNMODE} ) {
            croak "authen config error:  parameter LOGIN_RUNMODE is not a string"
              if ref $props->{LOGIN_RUNMODE};
            $config->{LOGIN_RUNMODE} = delete $props->{LOGIN_RUNMODE};
        }

        # Check for LOGIN_URL
        if ( defined $props->{LOGIN_URL} ) {
            carp "authen config warning:  parameter LOGIN_URL ignored since we already have LOGIN_RUNMODE"
              if $config->{LOGIN_RUNMODE};
            croak "authen config error:  parameter LOGIN_URL is not a string"
              if ref $props->{LOGIN_URL};
            $config->{LOGIN_URL} = delete $props->{LOGIN_URL};
        }

        # Check for LOGOUT_RUNMODE
        if ( defined $props->{LOGOUT_RUNMODE} ) {
            croak "authen config error:  parameter LOGOUT_RUNMODE is not a string"
              if ref $props->{LOGOUT_RUNMODE};
            $config->{LOGOUT_RUNMODE} = delete $props->{LOGOUT_RUNMODE};
        }

        # Check for LOGOUT_URL
        if ( defined $props->{LOGOUT_URL} ) {
            carp "authen config warning:  parameter LOGOUT_URL ignored since we already have LOGOUT_RUNMODE"
              if $config->{LOGOUT_RUNMODE};
            croak "authen config error:  parameter LOGOUT_URL is not a string"
              if ref $props->{LOGOUT_URL};
            $config->{LOGOUT_URL} = delete $props->{LOGOUT_URL};
        }

        # Check for CREDENTIALS
        if ( defined $props->{CREDENTIALS} ) {
            croak "authen config error:  parameter CREDENTIALS is not a string or arrayref"
              if ref $props->{CREDENTIALS} && Scalar::Util::reftype( $props->{CREDENTIALS} ) ne 'ARRAY';
            $config->{CREDENTIALS} = delete $props->{CREDENTIALS};
            # We will accept a string, but what we really want is an arrayref of the credentials
            no warnings qw(uninitialized);
            $config->{CREDENTIALS} = [ $config->{CREDENTIALS} ] if Scalar::Util::reftype( $config->{CREDENTIALS} ) ne 'ARRAY';
        }

        # Check for LOGIN_SESSION_TIMEOUT
        if ( defined $props->{LOGIN_SESSION_TIMEOUT} ) {
            croak "authen config error:  parameter LOGIN_SESSION_TIMEOUT is not a string or a hashref"
              if ref $props->{LOGIN_SESSION_TIMEOUT} && ref$props->{LOGIN_SESSION_TIMEOUT} ne 'HASH';
            my $options = {};
            if (! ref $props->{LOGIN_SESSION_TIMEOUT}) {
                $options->{IDLE_FOR} = _time_to_seconds( $props->{LOGIN_SESSION_TIMEOUT} );
                croak "authen config error: parameter LOGIN_SESSION_TIMEOUT is not a valid time string" unless defined $options->{IDLE_FOR};
            } else {
                if ($props->{LOGIN_SESSION_TIMEOUT}->{IDLE_FOR}) {
                    $options->{IDLE_FOR} = _time_to_seconds( delete $props->{LOGIN_SESSION_TIMEOUT}->{IDLE_FOR} );
                    croak "authen config error: IDLE_FOR option to LOGIN_SESSION_TIMEOUT is not a valid time string" unless defined $options->{IDLE_FOR};
                }
                if ($props->{LOGIN_SESSION_TIMEOUT}->{EVERY}) {
                    $options->{EVERY} = _time_to_seconds( delete $props->{LOGIN_SESSION_TIMEOUT}->{EVERY} );
                    croak "authen config error: EVERY option to LOGIN_SESSION_TIMEOUT is not a valid time string" unless defined $options->{EVERY};
                }
                if ($props->{LOGIN_SESSION_TIMEOUT}->{CUSTOM}) {
                    $options->{CUSTOM} = delete $props->{LOGIN_SESSION_TIMEOUT}->{CUSTOM};
                    croak "authen config error: CUSTOM option to LOGIN_SESSION_TIMEOUT must be a code reference" unless ref $options->{CUSTOM} eq 'CODE';
                }
                croak "authen config error: Invalid option(s) (" . join( ', ', keys %{$props->{LOGIN_SESSION_TIMEOUT}} ) . ") passed to LOGIN_SESSION_TIMEOUT" if %{$props->{LOGIN_SESSION_TIMEOUT}};
            }

            $config->{LOGIN_SESSION_TIMEOUT} = $options;
            delete $props->{LOGIN_SESSION_TIMEOUT};
        }

        # Check for POST_LOGIN_CALLBACK
        if ( defined $props->{POST_LOGIN_CALLBACK} ) {
            croak "authen config error:  parameter POST_LOGIN_CALLBACK is not a coderef"
              unless( ref $props->{POST_LOGIN_CALLBACK} eq 'CODE' );
            $config->{POST_LOGIN_CALLBACK} = delete $props->{POST_LOGIN_CALLBACK};
        }

        # Check for RENDER_LOGIN
        if ( defined $props->{RENDER_LOGIN} ) {
            croak "authen config error:  parameter RENDER_LOGIN is not a coderef"
              unless( ref $props->{RENDER_LOGIN} eq 'CODE' );
            $config->{RENDER_LOGIN} = delete $props->{RENDER_LOGIN};
        }

        # Check for LOGIN_FORM
        if ( defined $props->{LOGIN_FORM} ) {
            croak "authen config error:  parameter LOGIN_FORM is not a hashref"
              unless( ref $props->{LOGIN_FORM} eq 'HASH' );
            $config->{LOGIN_FORM} = delete $props->{LOGIN_FORM};
        }

	# Check for DETAINT_URL_REGEXP
        if ( defined $props->{DETAINT_URL_REGEXP} ) {
            $config->{DETAINT_URL_REGEXP} = delete $props->{DETAINT_URL_REGEXP};
        }
	else {
	    $config->{DETAINT_URL_REGEXP} =  '^([\w\_\%\?\&\;\-\/\@\.\+\$\=\#\:\!\*\"\'\(\)\,]+)$';
	}

        # Check for DETAINT_USERNAME_REGEXP
        if ( defined $props->{DETAINT_USERNAME_REGEXP} ) {
            $config->{DETAINT_USERNAME_REGEXP} = delete $props->{DETAINT_USERNAME_REGEXP};
        }
        else {
            $config->{DETAINT_USERNAME_REGEXP} =  '^([\w\_]+)$';
        }

        # If there are still entries left in $props then they are invalid
        croak "Invalid option(s) (" . join( ', ', keys %$props ) . ") passed to config" if %$props;
    }
}

=head2 protected_runmodes

This method takes a list of runmodes that are to be protected by authentication.  If a user
tries to access one of these runmodes, then they will be redirected to a login page
unless they are properly logged in.  The runmode names can be a list of simple strings, regular
expressions, or special directives that start with a colon.  This method is cumulative, so
if it is called multiple times, the new values are added to existing entries.  It returns
a list of all entries that have been saved so far.  Calling this function,
will not itself generate cookies or session ids.

=over 4

=item :all - All runmodes in this module will require authentication

=back

  # match all runmodes
  __PACKAGE__->authen->protected_runmodes(':all');

  # only protect runmodes one two and three
  __PACKAGE__->authen->protected_runmodes(qw(one two three));

  # protect only runmodes that start with auth_
  __PACKAGE__->authen->protected_runmodes(qr/^auth_/);

  # protect all runmodes that *do not* start with public_
  __PACKAGE__->authen->protected_runmodes(qr/^(?!public_)/);

=cut

sub protected_runmodes {
    my $self   = shift;
    my $config = $self->_config;

    $config->{PROTECTED_RUNMODES} ||= [];
    push @{$config->{PROTECTED_RUNMODES}}, @_ if @_;

    return @{$config->{PROTECTED_RUNMODES}};
}

=head2 is_protected_runmode

This method accepts the name of a runmode, and will tell you if that runmode is
a protected runmode (i.e. does a user need to be authenticated to access this runmode).
Calling this function, will not itself generate cookies or session ids.

=cut

sub is_protected_runmode {
    my $self = shift;
    my $runmode = shift;

    foreach my $runmode_test ($self->protected_runmodes) {
        if (overload::StrVal($runmode_test) =~ /^Regexp=/) {
            # We were passed a regular expression
            return 1 if $runmode =~ $runmode_test;
        } elsif (ref $runmode_test && ref $runmode_test eq 'CODE') {
            # We were passed a code reference
            return 1 if $runmode_test->($runmode);
        } elsif ($runmode_test eq ':all') {
            # all runmodes are protected
            return 1;
        } else {
            # assume we were passed a string
            return 1 if $runmode eq $runmode_test;
        }
    }

    # See if the user is using attributes
    my $sub = $self->_cgiapp->can($runmode);
    return 1 if $sub && $RUNMODES{$sub};

    return;
}

=head2 redirect_after_login

This method is be called during the prerun stage to
redirect the user to the page that has been configured
as the destination after a successful login.  The location is determined as follows:

=over 

=item POST_LOGIN_RUNMODE 

If the POST_LOGIN_RUNMODE config parameter is set, that run mode will be the chosen location.

=item POST_LOGIN_URL

If the above fails and the POST_LOGIN_URL config parameter is set, then there will be a 302 redirection to that location.

=item destination

If the above fails and there is a destination query parameter, which must a taint check against the DETAINT_URL_REGEXP config parameter,
then there will be a 302 redirection to that location.

=item original destination

If all the above fail then there the originally requested page will be delivered.

=back

=cut

sub redirect_after_login {
    my $self = shift;
    my $cgiapp = $self->_cgiapp;
    my $config = $self->_config;

    if ($config->{POST_LOGIN_RUNMODE}) {
        $cgiapp->prerun_mode($config->{POST_LOGIN_RUNMODE});
    } elsif ($config->{POST_LOGIN_URL}) {
        $cgiapp->header_add(-location => $config->{POST_LOGIN_URL});
        $cgiapp->header_type('redirect');
        $cgiapp->prerun_mode('authen_dummy_redirect');
    } elsif (my $destination = $cgiapp->authen->_detaint_destination()) {
        $cgiapp->header_add(-location => $destination);
        $cgiapp->header_type('redirect');
        $cgiapp->prerun_mode('authen_dummy_redirect');
    }
    return;
}

=head2 redirect_to_login

This method is be called during the prerun stage if
the current user is not logged in, and they are trying to
access a protected runmode.  It will redirect to the page
that has been configured as the login page, based on the value
of LOGIN_RUNMODE or LOGIN_URL  If nothing is configured
a simple login page will be automatically provided.

=cut

sub redirect_to_login {
    my $self = shift;
    my $cgiapp = $self->_cgiapp;
    my $config = $self->_config;

    if ($config->{LOGIN_RUNMODE}) {
        $cgiapp->prerun_mode($config->{LOGIN_RUNMODE});
    } elsif ($config->{LOGIN_URL}) {
        $cgiapp->header_add(-location => $config->{LOGIN_URL});
        $cgiapp->header_type('redirect');
        $cgiapp->prerun_mode('authen_dummy_redirect');
    } else {
        $cgiapp->prerun_mode('authen_login');
    }
}

=head2 redirect_to_logout

This method is called during the prerun stage if the user
has requested to be logged out.  It will redirect to the page
that has been configured as the logout page, based on the value
of LOGOUT_RUNMODE or LOGOUT_URL  If nothing is
configured, the page will redirect to the website homepage.

=cut

sub redirect_to_logout {
    my $self = shift;
    my $cgiapp = $self->_cgiapp;
    my $config = $self->_config;
    $self->logout();

    if ($config->{LOGOUT_RUNMODE}) {
        $cgiapp->prerun_mode($config->{LOGOUT_RUNMODE});
    } elsif ($config->{LOGOUT_URL}) {
        $cgiapp->header_add(-location => $config->{LOGOUT_URL});
        $cgiapp->header_type('redirect');
        $cgiapp->prerun_mode('authen_dummy_redirect');
    } else {
        $cgiapp->header_add(-location => '/');
        $cgiapp->header_type('redirect');
        $cgiapp->prerun_mode('authen_dummy_redirect');
    }
}

=head2 setup_runmodes

This method is called during the prerun stage to register some custom
runmodes that the Authentication plugin requires in order to function.
Calling this function, will not itself generate cookies or session ids.

=cut

sub setup_runmodes {
    my $self   = shift;
    my $config = $self->_config;

    $self->_cgiapp->run_modes( authen_login => \&authen_login_runmode )
      unless $config->{LOGIN_RUNMODE} || $config->{LOGIN_URL};
    $self->_cgiapp->run_modes( authen_logout => \&authen_logout_runmode )
      unless $config->{LOGOUT_RUNMODE} || $config->{LOGOUT_URL};
    $self->_cgiapp->run_modes( authen_dummy_redirect => \&authen_dummy_redirect );
    return;
}

=head2 last_login

This will return return the time of the last login for this user

  my $last_login = $self->authen->last_login;

This function will initiate a session or cookie if one has not been created already.

=cut

sub last_login {
    my $self = shift;
    my $new  = shift;
    $self->initialize;

    return unless $self->username;
    my $old = $self->store->fetch('last_login');
    $self->store->save('last_login' => $new) if $new;
    return $old;
}

=head2 last_access

This will return return the time of the last access for this user

  my $last_access = $self->authen->last_access;

This function will initiate a session or cookie if one has not been created already.

=cut

sub last_access {
    my $self = shift;
    my $new  = shift;
    $self->initialize;

    return unless $self->username;
    my $old = $self->store->fetch('last_access');
    $self->store->save('last_access' => $new) if $new;
    return $old;
}

=head2 is_login_timeout

This will return true or false depending on whether the users login status just timed out

  $self->add_message('login session timed out') if $self->authen->is_login_timeout;

This function will initiate a session or cookie if one has not been created already.

=cut

sub is_login_timeout {
    my $self = shift;
    $self->initialize;

    return $self->{is_login_timeout} ? 1 : 0;
}

=head2 is_authenticated

This will return true or false depending on the login status of this user

  assert($self->authen->is_authenticated); # The user should be logged in if we got here

This function will initiate a session or cookie if one has not been created already.

=cut

sub is_authenticated {
    my $self = shift;
    $self->initialize;

    return $self->username ? 1 : 0;
}

=head2 login_attempts

This method will return the number of failed login attempts have been made by this
user since the last successful login.  This is not a number that can be trusted,
as it is dependent on the underlying store to be able to return the correct value for
this user.  For example, if the store uses a cookie based session, the user trying
to login could delete their cookies, and hence get a new session which will not have
any login attempts listed.  The number will be cleared upon a successful login.
This function will initiate a session or cookie if one has not been created already.

=cut

sub login_attempts {
    my $self = shift;
    $self->initialize;

    my $la = $self->store->fetch('login_attempts');
    return $la;
}

=head2 username

This will return the username of the currently logged in user, or undef if
no user is currently logged in.

  my $username = $self->authen->username;

This function will initiate a session or cookie if one has not been created already.

=cut

sub username {
    my $self = shift;
    $self->initialize;

    my $u = $self->store->fetch('username');
    return $u;
}

=head2 is_new_login

This will return true or false depending on if this is a fresh login

  $self->log->info("New Login") if $self->authen->is_new_login;

This function will initiate a session or cookie if one has not been created already.

=cut

sub is_new_login {
    my $self = shift;
    $self->initialize;

    return $self->{is_new_login};
}

=head2 credentials

This method will return the names of the form parameters that will be
looked for during a login.  By default they are authen_username and authen_password,
but these values can be changed by supplying the CREDENTIALS parameters in the
configuration. Calling this function, will not itself generate cookies or session ids.

=cut

sub credentials {
    my $self = shift;
    my $config = $self->_config;
    return $config->{CREDENTIALS} || [qw(authen_username authen_password)];
}

=head2 logout

This will attempt to logout the user.  If during a request the Authentication
module sees a parameter called 'authen_logout', it will automatically call this method
to log out the user.

  $self->authen->logout();

This function will initiate a session or cookie if one has not been created already.

=cut

sub logout {
    my $self = shift;
    $self->initialize;

    $self->store->clear;
}

=head2 drivers

This method will return a list of driver objects that are used for
verifying the login credentials. Calling this function, will not itself generate cookies or session ids.

=cut

sub drivers {
    my $self = shift;

    if ( !$self->{drivers} ) {
        my $config = $self->_config;

        # Fetch the configuration parameters for the driver(s)
        my $driver_configs = defined $config->{DRIVER} ? $config->{DRIVER} : [['Dummy']];

        foreach my $driver_config (@$driver_configs) {
            my ($drivername, @params) = @$driver_config;
            # add support for Authen::Simple modules
            if (index($drivername, 'Authen::Simple') == 0) {
                unshift @params, $drivername;
                $drivername = 'Authen::Simple';
            }
            # Load the the class for this driver
            my $driver_class = _find_deligate_class(
                'CGI::Application::Plugin::Authentication::Driver::' . $drivername,
                $drivername
            ) || die "Driver ".$drivername." can not be found";

            # Create the driver object
            my $driver = $driver_class->new( $self, @params )
              || die "Could not create new $driver_class object";
            push @{$self->{drivers}}, $driver;
        }
    }

    my $drivers = $self->{drivers};
    return @$drivers[0..$#$drivers];
}

=head2 store

This method will return a store object that is used to store information
about the status of the authentication across multiple requests.
This function will initiate a session or cookie if one has not been created already.

=cut

sub store {
    my $self = shift;

    if ( !$self->{store} ) {
        my $config = $self->_config;

        # Fetch the configuration parameters for the store
        my ($store_module, @store_config);
        ($store_module, @store_config) = @{ $config->{STORE} } if $config->{STORE} && ref $config->{STORE} eq 'ARRAY';
        if (!$store_module) {
            # No STORE configuration was provided
            if ($self->_cgiapp->can('session') && UNIVERSAL::isa($self->_cgiapp->session, 'CGI::Session')) {
                # The user is already using the Session plugin
                ($store_module, @store_config) = ( 'Session' );
            } else {
                # Fall back to the Cookie Store
                ($store_module, @store_config) = ( 'Cookie' );
            }
        }

        # Load the the class for this store
        my $store_class = _find_deligate_class(
            'CGI::Application::Plugin::Authentication::Store::' . $store_module,
            $store_module
        ) || die "Store $store_module can not be found";

        # Create the store object
        $self->{store} = $store_class->new( $self, @store_config )
          || die "Could not create new $store_class object";
    }

    return $self->{store};
}

=head2 initialize

This does most of the heavy lifting for the Authentication plugin.  It will
check to see if the user is currently attempting to login by looking for the
credential form fields in the query object.  It will load the required driver
objects and authenticate the user.  It is OK to call this method multiple times
as it checks to see if it has already been executed and will just return
without doing anything if called multiple times.  This allows us to call
initialize as late as possible in the request so that no unnecessary work is
done.

The user will be logged out by calling the C<logout()> method if the login
session has been idle for too long, if it has been too long since the last
login, or if the login has timed out.  If you need to know if a user was logged
out because of a time out, you can call the C<is_login_timeout> method.

If all goes well, a true value will be returned, although it is usually not
necessary to check.

This function will initiate a session or cookie if one has not been created already.

=cut

sub initialize {
    my $self = shift;
    return 1 if $self->{initialized};

    # It would seem to make more sense to do this at the /end/ of the routine
    # but that causes an infinite loop. 
    $self->{initialized} = 1;

    if (UNIVERSAL::can($self->_cgiapp, 'devpopup')) {
        $self->_cgiapp->add_callback( 'devpopup_report', \&_devpopup_report );
    }

    my $config = $self->_config;

    # See if the user is trying to log in
    #  We do this before checking to see if the user is already logged in, since
    #  a logged in user may want to log in as a different user.
    my $field_names = $config->{CREDENTIALS} || [qw(authen_username authen_password)];

    my $query = $self->_cgiapp->query;
    my @credentials = map { scalar $query->param($_) } @$field_names;
    if ($credentials[0]) {
        # The user is trying to login
        # make sure if they are already logged in, that we log them out first
        my $store = $self->store;
        $store->clear if $store->fetch('username');
        foreach my $driver ($self->drivers) {
            if (my $username = $driver->verify_credentials(@credentials)) {
                # This user provided the correct credentials
                # so save this new login in the store
                my $now = time();
                $store->save( username => $username,  login_attempts => 0, last_login => $now, last_access => $now );
                $self->{is_new_login} = 1;
                # See if we are remembering the username for this user
                my $login_config = $config->{LOGIN_FORM} || {};
                if ($login_config->{REMEMBERUSER_OPTION} && scalar $query->param('authen_rememberuser')) {
                    my $cookie = $query->cookie(
                        -name   => $login_config->{REMEMBERUSER_COOKIENAME} || 'CAPAUTHTOKEN',
                        -value  => $username,
                        -expiry => '10y',
                    );
                    $self->_cgiapp->header_add(-cookie => [$cookie]);
                }
                last;
            }
        }
        unless ($self->username) {
            # password mismatch - increment failed login attempts
            my $attempts = $store->fetch('login_attempts') || 0; 
            $store->save( login_attempts => $attempts + 1 );
        }

        $config->{POST_LOGIN_CALLBACK}->($self->_cgiapp) 
          if($config->{POST_LOGIN_CALLBACK});
    }

    # Check the user name last of all because only this check might create a session behind the scenes.
    # In other words if a website works perfectly well without authentication,
    # then adding a protected run mode should not add session to the unprotected modes.
    # See 60_parsimony.t for the test.
    if ($config->{LOGIN_SESSION_TIMEOUT} && !$self->{is_new_login} && $self->username) {
        # This is not a fresh login, and there are time out rules, so make sure the login is still valid
        if ($config->{LOGIN_SESSION_TIMEOUT}->{IDLE_FOR} && time() - $self->last_access >= $config->{LOGIN_SESSION_TIMEOUT}->{IDLE_FOR}) {
            # this login has been idle for too long
            $self->{is_login_timeout} = 1;
            $self->logout;
        } elsif ($config->{LOGIN_SESSION_TIMEOUT}->{EVERY} && time() - $self->last_login >=  $config->{LOGIN_SESSION_TIMEOUT}->{EVERY}) {
            # it has been too long since the last login
            $self->{is_login_timeout} = 1;
            $self->logout;
        } elsif ($config->{LOGIN_SESSION_TIMEOUT}->{CUSTOM} && $config->{LOGIN_SESSION_TIMEOUT}->{CUSTOM}->($self)) {
            # this login has timed out
            $self->{is_login_timeout} = 1;
            $self->logout;
        }
    }
    return 1;

}

=head2 display 

This method will return the
L<CGI::Application::Plugin::Authentication::Display> object, creating
and caching it if necessary.

=cut

sub display {
    my $self = shift;
    return $self->{display} if $self->{display};
    my $config = $self->_config->{LOGIN_FORM} || {};
    my $class = "CGI::Application::Plugin::Authentication::Display::".
        ($config->{DISPLAY_CLASS} || 'Classic');
    $class->require;
    $self->{display} = $class->new($self->_cgiapp);
    return $self->{display};
}

=head2 login_box

This method will return the HTML for a login box that can be
embedded into another page.  This is the same login box that is used
in the default authen_login runmode that the plugin provides.

This function will initiate a session or cookie if one has not been created already.

=cut

sub login_box {
    my $self = shift;
    return $self->display->login_box;
}

=head2 new

This method creates a new CGI::Application::Plugin::Authentication object.  It requires
as it's only parameter a CGI::Application object.  This method should never be called
directly, since the 'authen' method that is imported into the CGI::Application module
will take care of creating the CGI::Application::Plugin::Authentication object when it
is required. Calling this function, will not itself generate cookies or session ids.

=cut

sub new {
    my $class  = shift;
    my $cgiapp = shift;
    my $self   = {};

    bless $self, $class;
    $self->{cgiapp} = $cgiapp;
    Scalar::Util::weaken($self->{cgiapp}); # weaken circular reference

    return $self;
}

=head2 instance

This method works the same way as 'new', except that it returns the same Authentication
object for the duration of the request.  This method should never be called
directly, since the 'authen' method that is imported into the CGI::Application module
will take care of creating the CGI::Application::Plugin::Authentication object when it
is required. Calling this function, will not itself generate cookies or session ids.

=cut

sub instance {
    my $class  = shift;
    my $cgiapp = shift;
    die "CGI::Application::Plugin::Authentication->instance must be called with a CGI::Application object"
      unless defined $cgiapp && UNIVERSAL::isa( $cgiapp, 'CGI::Application' );

    $cgiapp->{__CAP_AUTHENTICATION_INSTANCE} = $class->new($cgiapp) unless defined $cgiapp->{__CAP_AUTHENTICATION_INSTANCE};
    return $cgiapp->{__CAP_AUTHENTICATION_INSTANCE};
}


=head1 CGI::Application CALLBACKS

=head2 prerun_callback

This method is a CGI::Application prerun callback that will be
automatically registered for you if you are using CGI::Application
4.0 or greater.  If you are using an older version of CGI::Application
you will have to create your own cgiapp_prerun method and make sure you
call this method from there.

 sub cgiapp_prerun {
    my $self = shift;

    $self->CGI::Application::Plugin::Authentication::prerun_callback();
 }

=cut

sub prerun_callback {
    my $self = shift;
    my $authen = $self->authen;

    $authen->initialize;

    # setup the default login and logout runmodes
    $authen->setup_runmodes;

    # The user is asking to be logged out
    if (scalar $self->query->param('authen_logout')) {
        # The user wants to logout
        return $self->authen->redirect_to_logout;
    }

    # If the user just logged in then we may want to redirect them
    if ($authen->is_new_login) {
        # User just logged in, so where to we send them?
        return $self->authen->redirect_after_login;
    }

    # Update any time out info
    my $config = $authen->_config;
    if ( $config->{LOGIN_SESSION_TIMEOUT} ) {
        # update the last access time
        my $now = time;
        $authen->last_access($now);
    }

    # If a perun mode is set check against that. 
    # This allows cooperation with plugins such as CAP::ActionDispatch
    # that also have preun hooks.
    # Note the comments in the CGI::Application docs on the ordering of
    # callback execution.
    my $run_mode = $self->prerun_mode;
    $run_mode ||= $self->get_current_runmode;
    
    if ( $authen->is_protected_runmode( $run_mode ) ) {
        # This runmode requires authentication
        unless ($authen->is_authenticated) {
            # This user is NOT logged in
            return $self->authen->redirect_to_login;
        }
    }
}

=head1 CGI::Application RUNMODES

=head2 authen_login_runmode

This runmode is provided if you do not want to create your
own login runmode.  It will display a simple login form for the user, which
can be replaced by assigning RENDER_LOGIN a coderef that returns the HTML.

=cut

sub authen_login_runmode {
    my $self   = shift;
    my $authen = $self->authen;

    my $credentials = $authen->credentials;
    my $username    = $credentials->[0];
    my $password    = $credentials->[1];

    my $html;
    if ( my $sub = $authen->_config->{RENDER_LOGIN} ) {
        $html = $sub->($self);
    }
    else {
        $html = join( "\n",
            CGI::start_html( -title => $authen->display->login_title ),
            $authen->display->login_box,
            CGI::end_html(),
        );
    }

    return $html;
}

=head2 authen_dummy_redirect

This runmode is provided for convenience when an external redirect needs
to be done.  It just returns an empty string.

=cut

sub authen_dummy_redirect {
    return '';
}

###
### Detainting helper methods
###

sub _detaint_destination {
    my $self = shift;
    my $query       = $self->_cgiapp->query;
    my $destination = scalar $query->param('destination');
    my $regexp = $self->_config->{DETAINT_URL_REGEXP};
    if ($destination && $destination =~ /$regexp/) {
	$destination = $1;
    }
    else {
	$destination = "";
    }
    return $destination;
}

sub _detaint_selfurl {
    my $self = shift;
    my $query       = $self->_cgiapp->query;
    my $destination = "";
    my $regexp = $self->_config->{DETAINT_URL_REGEXP};
    if ($query->self_url =~ /$regexp/) {
        $destination = $1;
    }
    return $destination;
}

sub _detaint_url {
    my $self = shift;
    my $query       = $self->_cgiapp->query;
    my $regexp = $self->_config->{DETAINT_URL_REGEXP};
    my $url = "";
    if ($query->url( -absolute => 1, -path_info => 1 ) =~ /$regexp/) {
        $url = $1;
    }
    return $url;
}

sub _detaint_username {
    my $self = shift;
    my $username = shift;
    my $cookiename = shift;
    my $query       = $self->_cgiapp->query;
    my $regexp = $self->_config->{DETAINT_USERNAME_REGEXP};
    my $username_value = "";
    if ((scalar $query->param($username) || $query->cookie($cookiename) || '') =~ /$regexp/) {
        $username_value = $1;
    }
    return $username_value;
}
 
###
### Helper methods
###

sub _cgiapp {
    return $_[0]->{cgiapp};
}

sub _find_deligate_class {
    foreach my $class (@_) {
        $class->require && return $class;
    }
    return;
}

sub _config {
    my $self  = shift;
    my $class = ref $self ? ref $self : $self;
    my $config;
    if ( ref $self ) {
        $config = $self->{__CAP_AUTHENTICATION_CONFIG} ||= $__CONFIG{$class} || {};
    } else {
        $__CONFIG{$class} ||= {};
        $config = $__CONFIG{$class};
    }
    return $config;
}

sub _devpopup_report {
    my $cgiapp = shift;
    my @list;
    my $self=$cgiapp->authen;
    if ($self->username) {
        push @list,['username',$self->username];
    }
    my $config = $self->_config;
    my $field_names = $config->{CREDENTIALS} || [qw(authen_username authen_password)];
    my $query = $cgiapp->query;
    foreach my $name (@$field_names) {
        push @list, [ $name, scalar $query->param($name) || ''];
    }
    my $r=0;
    my $text = join $/, map {
                    $r=1-$r;
                    qq(<tr class="@{[$r?'odd':'even']}"><td valign="top">$_->[0]</td><td>$_->[1]</td></tr>)
                    }
                    @list;
    $cgiapp->devpopup->add_report(
        title   => 'Authentication',
        summary => '',
        report  => qq(
            <style type="text/css">
              tr.even{background-color:#eee}
            </style>
            <div style="font-size: 80%">
              <table>
                <thead><tr><th>Parameter</th><th>Value</th></tr></thead>
                <tbody>$text</tbody>
              </table>
            </div>
        ),
    );
}

###
### Helper functions
###

sub _time_to_seconds {
    my $time = shift;
    return unless defined $time;

    # Most of this function is borrowed from CGI::Util v1.4 by Lincoln Stein
    my (%mult) = (
        's' => 1,
        'm' => 60,
        'h' => 60 * 60,
        'd' => 60 * 60 * 24,
        'w' => 60 * 60 * 24 * 7,
        'M' => 60 * 60 * 24 * 30,
        'y' => 60 * 60 * 24 * 365
    );
    # format for time can be in any of the forms...
    # "180" -- in 180 seconds
    # "180s" -- in 180 seconds
    # "2m" -- in 2 minutes
    # "12h" -- in 12 hours
    # "1d"  -- in 1 day
    # "4w"  -- in 4 weeks
    # "3M"  -- in 3 months
    # "2y"  -- in 2 years
    my $offset;
    if ( $time =~ /^([+-]?(?:\d+|\d*\.\d*))([smhdwMy]?)$/ ) {
        return if (!$2 || $2 eq 's') && $1 != int $1; # 
        $offset = int ( ( $mult{$2} || 1 ) * $1 );
    }
    return $offset;
}


=head1 EXAMPLE

In a CGI::Application module:

  use base qw(CGI::Application);
  use CGI::Application::Plugin::AutoRunmode;
  use CGI::Application::Plugin::Session;
  use CGI::Application::Plugin::Authentication;

  __PACKAGE__->authen->config(
        DRIVER         => [ 'Generic', { user1 => '123' } ],
        STORE          => 'Session',
        LOGOUT_RUNMODE => 'start',
  );
  __PACKAGE__->authen->protected_runmodes(qr/^auth_/, 'one');

  sub start : RunMode {
    my $self = shift;

  }

  sub one : RunMode {
    my $self = shift;

    # The user will only get here if they are logged in
  }

  sub auth_two : RunMode {
    my $self = shift;

    # This is also protected because of the
    # regexp call to protected_runmodes above
  }

=head1 COMPATIBILITY WITH L<CGI::Application::Plugin::ActionDispatch>

The prerun callback has been modified so that it will check for the presence of a prerun mode.
This is for compatibility with L<CGI::Application::Plugin::ActionDispatch>. This
change should be considered experimental. It is necessary to load the ActionDispatch
module so that the two prerun callbacks will be called in the correct order.

=head1 RECOMMENDED USAGE

=over

=item CSS

The best practice nowadays is generally considered to be to not have CSS
embedded in HTML. Thus it should be best to set LOGIN_FORM -> DISPLAY_CLASS to 
'Basic'.

=item Post login destination

Of the various means of selecting a post login destination the most secure would
seem to be POST_LOGIN_URL. The C<destination> parameter could potentially be hijacked by hackers.
The POST_LOGIN_RUNMODE parameter requires a hidden parameter that could potentially
be hijacked.

=item Taint mode

Do run your code under taint mode. It should help protect your application
against a number of attacks.

=item URL and username checking 

Please set the C<DETAINT_URL_REGEXP> and C<DETAINT_USERNAME_REGEXP> parameters
as tightly as possible. In particular you should prevent the destination parameter 
being used to redirect authenticated users to external sites; unless of course that
is what you want in which case that site should be the only possible external site. 

=item The login form

The HTML currently generated does not seem to be standards compliant as per
RT bug 58023. Also the default login form includes hidden forms which could
conceivably be hijacked. 
Set LOGIN_FORM -> DISPLAY_CLASS to 'Basic' to fix this.

=back

=head1 TODO

There are lots of things that can still be done to improve this plugin.  If anyone else is interested
in helping out feel free to dig right in.  Many of these things don't need my input, but if you want
to avoid duplicated efforts, send me a note, and I'll let you know of anyone else is working in the same area.

=over 4

=item review the code for security bugs and report

=item complete the separation of presentation and logic

=item write a tutorial

=item build more Drivers (Class::DBI, LDAP, Radius, etc...)

=item Add support for method attributes to identify runmodes that require authentication

=item finish the test suite

=item provide more example code

=item clean up the documentation

=item build a DB driver that builds it's own table structure.  This can be used by people that don't have their own user database to work with, and could include a simple user management application.


=back

=head1 BUGS

This is alpha software and as such, the features and interface
are subject to change.  So please check the Changes file when upgrading.

Some of the test scripts appear to be incompatible with versions of
L<Devel::Cover> later than 0.65.

=head1 SEE ALSO

L<CGI::Application>, perl(1)


=head1 AUTHOR

Author: Cees Hek <ceeshek@gmail.com>; Co-maintainer: Nicholas Bamber <nicholas@periapt.co.uk>.

=head1 CREDITS

Thanks to L<SiteSuite|http://www.sitesuite.com.au> for funding the 
development of this plugin and for releasing it to the world.

Thanks to Christian Walde for suggesting changes to fix the incompatibility with 
L<CGI::Application::Plugin::ActionDispatch> and for help with github.

Thanks to Alexandr Ciornii for pointing out some typos.

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2005, SiteSuite. All rights reserved.
Copyright (c) 2010, Nicholas Bamber. (Portions of the code).

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

The background images in the default login forms are used courtesy of 
L<www.famfamfam.com|http://www.famfamfam.com/lab/icons/silk/>. Those icons
are issued under the
L<Creative Commons Attribution 3.0 License|http://creativecommons.org/licenses/by/3.0/>.
Those icons are copyrighted 2006 by Mark James <mjames at gmail dot com>

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.

=cut

1;
