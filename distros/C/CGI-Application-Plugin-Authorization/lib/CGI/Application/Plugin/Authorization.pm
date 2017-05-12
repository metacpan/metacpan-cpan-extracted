package CGI::Application::Plugin::Authorization;

use strict;
use vars qw($VERSION);
$VERSION = '0.07';

our %__CONFIG;

use UNIVERSAL::require;
use Scalar::Util;
use List::Util qw(first);
use Carp;

sub import {
    my $pkg     = shift;
    my $callpkg = caller;
    {
        no strict qw(refs);
        *{ $callpkg . '::authz' }
            = \&CGI::Application::Plugin::_::Authorization::authz;
        *{ $callpkg . '::authorization' }
            = \&CGI::Application::Plugin::_::Authorization::authz;
    }
    if ( !UNIVERSAL::isa( $callpkg, 'CGI::Application' ) ) {
        warn
            "Calling package is not a CGI::Application module so not setting up the prerun hook.  If you are using \@ISA instead of 'use base', make sure it is in a BEGIN { } block, and make sure these statements appear before the plugin is loaded";
    }
    elsif ( !UNIVERSAL::can( $callpkg, 'add_callback' ) ) {
        warn
            "You are using an older version of CGI::Application that does not support callbacks, so the prerun method can not be registered automatically (Lookup 'CGI::Application CALLBACKS' in the docs for more info)";
    }
    else {
        $callpkg->add_callback( prerun => \&prerun_callback );
    }
}

=head1 NAME

CGI::Application::Plugin::Authorization - Authorization framework for
CGI::Application


=head1 SYNOPSIS

 use base qw(CGI::Application);
 use CGI::Application::Plugin::Authentication;
 use CGI::Application::Plugin::Authorization;

 # default config for runmode authorization
 __PACKAGE__->authz->config(
     DRIVER => [ 'HTGroup', FILE => 'htgroup' ],
 );

 # Using a named configuration to distinguish it from
 # the above configuration
 __PACKAGE__->authz('dbaccess')->config(
     DRIVER => [ 'DBI',
         DBH   => $self->dbh,
         TABLES      => ['user', 'access'],
         JOIN_ON     => 'user.id = access.user_id',
         CONSTRAINTS => {
             'user.name'      => '__USERNAME__',
             'access.table'   => '__PARAM_1__',
             'access.item_id' => '__PARAM_2__'
         }
     ],
 );

 sub admin_runmode {
    my $self = shift;

    # User must be in the admin group to have access to this runmode
    return $self->authz->forbidden unless $self->authz->authorize('admin');

    # rest of the runmode
    ...
 }

 sub update_widget {
    my $self = shift;
    my $widget = $self->query->param('widget_id');

    # Can this user edit this widget in the widgets table?
    return $self->authz->forbidden unless $self->authz('dbaccess')->authorize(widgets => $widget);

    # save changes to the widget
    ...
 }

=head1 DESCRIPTION

CGI::Application::Plugin::Authorization adds the ability to authorize users for
specific tasks.  Once a user has been authenticated and you know who you are
dealing with, you can then use this plugin to control what that user has access
to.  It imports two methods (C<authz> and C<authorization>) into your
L<CGI::Application> module.  Both of these methods are interchangeable, so you
should choose one and use it consistently throughout your code.  Through the
authz method you can call all the methods of the
CGI::Application::Plugin::Authorization plugin.

=head2 Named Configurations

There could be multiple ways that you may want to authorize actions in
different parts of your code.  These differences may conflict with each other.
For example you may have runmode level authorization that requires that the
user belongs to a certain group.  But secondly, you may have row level database
authorization that requires that the username column of the table contains the
name of the current user.  These configurations would conflict with each other
since they are authorizing using different information.  To solve this you can
create multiple named configurations, by specifying a unique name to the
c<authz> method.

 __PACKAGE__->authz('dbaccess')->config(
     DRIVER => [ 'DBI', ... ],
 );
 # later
 $self->authz('dbaccess')->authorize(widgets => $widget_id);



=head1 EXPORTED METHODS

=head2 authz -and- authorization

These methods are interchangeable and provided for users that either prefer
brevity, or clarity.  Everything is controlled through this method call, which
will return a CGI::Application::Plugin::Authorization object, or just the class
name if called as a class method.  When using the plugin, you will always first
call $self->authz or __PACKAGE__->authz and then the method you wish to invoke.
You can create multiple named authorization modules by providing a unique name
to the call to authz.  This will allow you to handle different types of
authorization in your modules.  For example, you could use the main
configuration to do runmode level authorization, and use a named configuration
to manage database row level authorization.


=cut

{
    package    # Hide from PAUSE
        CGI::Application::Plugin::_::Authorization;

    ##############################################
    ###
    ###   authorization
    ###
    ##############################################
    #
    # Return an authorization object that can be used
    # for managing authorization.
    #
    # This will return a class name if called
    # as a class, and a singleton object
    # if called as an object method
    #
    sub authz {
        my $cgiapp = shift;
        my $name   = shift || '__default__';

        if ( ref($cgiapp) ) {
            return CGI::Application::Plugin::Authorization->instance(
                ref($cgiapp) . '-' . $name, $cgiapp );
        }
        else {
            return CGI::Application::Plugin::Authorization->instance(
                $cgiapp . '-' . $name, $cgiapp );
        }
    }

}

package CGI::Application::Plugin::Authorization;

=head1 METHODS

=head2 config

This method is used to configure the CGI::Application::Plugin::Authorization
module.  It can be called as an object method, or as a class method.

The following parameters are accepted:

=over 4

=item DRIVER

Here you can choose which authorization module(s) you want to use to perform
the authorization.  For simplicity, you can leave off the
CGI::Application::Plugin::Authorization::Driver:: part when specifying the
DRIVER parameter.  If this module requires extra parameters, you can pass an
array reference that contains as the first parameter the name of the module,
and the required parameters as the rest of the array.  You can provide multiple
drivers which will be used, in order, to check the permissions until a valid
response is received.

  DRIVER => [ 'DBI', dbh => $self->dbh ],

  - or -

  DRIVER => [
    [ 'HTGroup', file => '.htgroup' ],
    [ 'LDAP', binddn => '...', host => 'localhost', ... ]
  ],


=item FORBIDDEN_RUNMODE

Here you can specify a runmode that the user will be redirected to if they fail
the authorization checks.

  FORBIDDEN_RUNMODE => 'forbidden'

=item FORBIDDEN_URL

If your forbidden page is external to this module, then you can use this option
to specify a URL that the user will be redirected to when they fail the
authorization checks. If both FORBIDDEN_URL and FORBIDDEN_RUNMODE are
specified, then the latter will take precedence.

  FORBIDDEN_URL => 'http://example.com/forbidden.html'

=item GET_USERNAME

This option allows you to provide a method that should return us the username
of the currently logged in user.  It will be passed the current authz objects
as the only parameter.  This is not a required option, and can be omitted if
you use the Authentication plugin, or if your authentication system sets
$ENV{REMOTE_USER}.

  GET_USERNAME => sub { my $authz = shift; return $authz->cgiapp->my_username }


=back

=cut

sub config {
    my $self  = shift;
    my $class = ref $self;

    die
        "Calling config after the Authorization object has already been created"
        if $self->{loaded};
    my $config = $self->_config;

    if (@_) {
        my $props;
        if ( ref( $_[0] ) eq 'HASH' ) {
            my $rthash = %{ $_[0] };
            $props = CGI::Application->_cap_hash( $_[0] );
        }
        else {
            $props = CGI::Application->_cap_hash( {@_} );
        }

        # Check for DRIVER
        if ( defined $props->{DRIVER} ) {
            croak
                "authz config error:  parameter DRIVER is not a string or arrayref"
                if ref $props->{DRIVER}
                && Scalar::Util::reftype( $props->{DRIVER} ) ne 'ARRAY';
            $config->{DRIVER} = delete $props->{DRIVER};
            # We will accept a string, or an arrayref of options, but what we
            # really want is an array of arrayrefs of options, so that we can
            # support multiple drivers each with their own custom options
            no warnings qw(uninitialized);
            $config->{DRIVER} = [ $config->{DRIVER} ]
                if Scalar::Util::reftype( $config->{DRIVER} ) ne 'ARRAY';
            $config->{DRIVER} = [ $config->{DRIVER} ]
                if Scalar::Util::reftype( $config->{DRIVER}->[0] ) ne 'ARRAY';
        }

        # Check for FORBIDDEN_RUNMODE
        if ( defined $props->{FORBIDDEN_RUNMODE} ) {
            croak
                "authz config error:  parameter FORBIDDEN_RUNMODE is not a string"
                if ref $props->{FORBIDDEN_RUNMODE};
            $config->{FORBIDDEN_RUNMODE} = delete $props->{FORBIDDEN_RUNMODE};
        }

        # Check for FORBIDDEN_URL
        if ( defined $props->{FORBIDDEN_URL} ) {
            carp
                "authz config warning:  parameter FORBIDDEN_URL ignored since we already have FORBIDDEN_RUNMODE"
                if $config->{FORBIDDEN_RUNMODE};
            croak
                "authz config error:  parameter FORBIDDEN_URL is not a string"
                if ref $props->{FORBIDDEN_URL};
            $config->{FORBIDDEN_URL} = delete $props->{FORBIDDEN_URL};
        }

        # Check for GET_USERNAME
        if ( defined $props->{GET_USERNAME} ) {
            croak
                "authz config error:  parameter GET_USERNAME is not a CODE reference"
                if ref $props->{GET_USERNAME} ne 'CODE';
            $config->{GET_USERNAME} = delete $props->{GET_USERNAME};
        }

        # If there are still entries left in $props then they are invalid
        croak "Invalid option(s) ("
            . join( ', ', keys %$props )
            . ") passed to config"
            if %$props;
    }
}

=head2 authz_runmodes

This method takes a list of runmodes that are to be authorized, and
the authorization rules for said runmodes.  If a user tries to access
one of these runmodes, then they will be redirected to the forbidden
page unless authorization is granted.

The runmode names can be simple strings, regular expressions, coderefs
(which are passed the name of the runmode as their only parameter), or
special directives that start with a colon.

The authorization rules can be simple strings representing the name of
the group that the user must be a member of, as a list-ref of group
names (of which the user only has to be a member of B<any one of the
groups>, or as a code-ref that will be called (with I<no> parameters).

This method is cumulative, so if it is called multiple times, the new
values are appended to the list of existing entries.  It returns a list
containing all of the entries that have been configured thus far.

B<NOTE:> compatibility with the interface as was defined in 0.06 B<is>
preserved.  0.06 allowed for runmodes to be passed in as a list-ref of
two-element lists to specify authorization rules.  Although this
interface is supported, the extra list-refs aren't necessary.

=over 4

=item :all - All runmodes in this module will require authorization

=back

  # match all runmodes
  __PACKAGE__->authz->authz_runmodes(
      ':all' => 'admin',
      );

  # only protect runmodes one and two
  __PACKAGE__->authz->authz_runmodes(
      one => 'admin',
      two => 'admin',
      );

  # protect only runmodes that start with auth_
  __PACKAGE__->authz->authz_runmodes(
      qr/^authz_/ => 'admin',
      );

  # protect all runmodes that *do not* start with public_
  __PACKAGE__->authz->authz_runmodes(
      qr/^(?!public_)/ => 'admin',
      );

  # preserve the interface from 0.06:
  __PACKAGE__->authz->authz_runmodes(
      [':all' => 'admin'],
      );

=cut

sub authz_runmodes {
    my $self   = shift;
    my $config = $self->_config;

    $config->{AUTHZ_RUNMODES} ||= [];

    while (@_) {
      my ($rm, $group);

      # extract next runmode/authz rule from args
      if (ref($_[0]) eq 'ARRAY') {
        # 0.06 interface; list-ref
        my $rule = shift @_;
        ($rm, $group) = @{$rule};
      }
      else {
        # new interface; list
        $rm = shift @_;
        $group = shift @_;
      }

      # add authz rule to our config
      push( @{$config->{AUTHZ_RUNMODES}}, [$rm, $group] );
    }

    return @{$config->{AUTHZ_RUNMODES}};
}

=head2 is_authz_runmode

This method accepts the name of a runmode, and if that runmode requires
authorization (ie the user needs to be a member of a particular group
or has to satisfy some other authorization rule) then this method
returns the corresponding authorization rule which must be satisfied
(which could be either a scalar, a list-ref, or a code-ref, depending
on how the rules were defined).

=cut

sub is_authz_runmode {
    my $self = shift;
    my $runmode = shift;

    foreach my $runmode_info ($self->authz_runmodes) {
      my ($runmode_test, $rule) = @$runmode_info;
      if (overload::StrVal($runmode_test) =~ /^Regexp=/) {
	# We were passed a regular expression
	return $rule if $runmode =~ $runmode_test;
      } elsif (ref $runmode_test && ref $runmode_test eq 'CODE') {
	# We were passed a code reference
	return $rule if $runmode_test->($runmode);
      } elsif ($runmode_test eq ':all') {
	# all runmodes are protected
	return $rule;
      } else {
	# assume we were passed a string
	return $rule if $runmode eq $runmode_test;
      }
    }

    return undef;
}

=head2 new

This method creates a new L<CGI::Application::Plugin::Authorization> object.
It requires as it's only parameter a L<CGI::Application> object.  This method
should never be called directly, since the C<authz> method that is imported
into the L<CGI::Application> module will take care of creating the
L<CGI::Application::Plugin::Authorization> object when it is required.

=cut

sub new {
    my $class  = shift;
    my $name   = shift;
    my $cgiapp = shift;
    my $self   = {};

    bless $self, $class;
    $self->{name}   = $name;
    $self->{cgiapp} = $cgiapp;
    Scalar::Util::weaken( $self->{cgiapp} )
        if ref $self->{cgiapp};    # weaken circular reference

    return $self;
}

=head2 instance

This method works the same way as C<new>, except that it returns the same
Authorization object for the duration of the request.  This method should never
be called directly, since the C<authz> method that is imported into the
L<CGI::Application> module will take care of creating the
L<CGI::Application::Plugin::Authorization> object when it is required.

=cut

sub instance {
    my $class  = shift;
    my $name   = shift ||'';
    my $cgiapp = shift;
    die
        "CGI::Application::Plugin::Authorization->instance must be called with a CGI::Application object or class name"
        unless defined $cgiapp
        && UNIVERSAL::isa( $cgiapp, 'CGI::Application' );

    if ( ref $cgiapp ) {
        # being called from a CGI::Application object
        $cgiapp->{__CAP_AUTHORIZATION_INSTANCE}->{$name}
            = $class->new( $name, $cgiapp )
            unless defined $cgiapp->{__CAP_AUTHORIZATION_INSTANCE}->{$name};
        return $cgiapp->{__CAP_AUTHORIZATION_INSTANCE}->{$name};
    }
    else {
        # being called from a CGI::Application class
        return $class->new( $name, $cgiapp );
    }
}

=head2 authorize

This method will test to see if the current user has access to the given
resource.  It will take the given parameters and test them against the DRIVER
classes that have been configured.  A true return value means the user should
have access to the given resource.

 # is the current user in the admin group
 if ($self->authz->authorize('admingroup')) {
    # perform an admin action
 }

=cut

sub authorize {
    my $self   = shift;
    my @params = @_;

    foreach my $driver ( $self->drivers ) {
        return 1 if $driver->authorize(@params);
    }
    return 0;
}

=head2 username

This method will return the name of the currently logged in user.  It uses
three different methods to figure out the username:

=over 4

=item GET_USERNAME option

Use the subroutine provided by the GET_USERNAME option to figure out the
current username

=item CGI::Application::Plugin::Authentication

See if the L<CGI::Application::Plugin::Authentication> plugin is being used,
and retrieve the username through this plugin

=item REMOTE_USER

See if the REMOTE_USER environment variable is set and use that value

=back

=cut

sub username {
    my $self   = shift;
    my $config = $self->_config;

    if ( $config->{GET_USERNAME} ) {
        return $config->{GET_USERNAME}->($self);
    }
    elsif ( $self->cgiapp->can('authen') ) {
        return $self->cgiapp->authen->username;
    }
    else {
        return $ENV{REMOTE_USER};
    }
}

=head2 drivers

This method will return a list of driver objects that are used for
this authorization instance.

=cut

sub drivers {
    my $self = shift;

    if ( !$self->{drivers} ) {
        my $config = $self->_config;

        # Fetch the configuration parameters for the driver(s)
        my $driver_configs
            = defined $config->{DRIVER} ? $config->{DRIVER} : [ ['Dummy'] ];

        foreach my $driver_config (@$driver_configs) {
            my ( $drivername, @params ) = @$driver_config;
            # Load the the class for this driver
            my $driver_class = _find_delegate_class(
                'CGI::Application::Plugin::Authorization::Driver::'
                    . $drivername, $drivername
                )
                || die "Driver " . $drivername . " can not be found";

            # Create the driver object
            my $driver = $driver_class->new( $self, @params )
                || die "Could not create new $driver_class object";
            push @{ $self->{drivers} }, $driver;
        }
        $self->{loaded} = 1;
    }

    my $drivers = $self->{drivers};
    return @$drivers[ 0 .. $#$drivers ];
}

=head2 cgiapp

This will return the underlying CGI::Application object.

=cut

sub cgiapp {
    return $_[0]->{cgiapp};
}


=head2 setup_runmodes

This method is called during the prerun stage to register some custom
runmodes that the Authentication plugin requires in order to function.

=cut

sub setup_runmodes {
    my $self = shift;
    $self->cgiapp->run_modes( authz_dummy_redirect => \&authz_dummy_redirect );
    $self->cgiapp->run_modes( authz_forbidden      => \&authz_forbidden );
    return;
}

=head1 CGI::Application CALLBACKS

We'll automatically add the C<authz_forbidden> run mode if you are using
CGI::Application 4.0 or greater. 

If you are using an older version of CGI::Application you will need to add it yourself.

 sub cgiapp_prerun {
    my $self = shift;

    $self->run_modes( authz_forbidden => \&CGI::Application::Plugin::Authorization::authz_forbidden, );
 }

=cut

=head2 prerun_callback

This method is a CGI::Application prerun callback that will be
automatically registered for you if you are using CGI::Application
4.0 or greater.  If you are using an older version of CGI::Application
you will have to create your own cgiapp_prerun method and make sure you
call this method from there.

 sub cgiapp_prerun {
    my $self = shift;

    $self->CGI::Application::Plugin::Authorization::prerun_callback();
 }

=cut

sub prerun_callback {
  my $self = shift;
  my $authz = $self->authz;
  my $rule = undef;

  # setup the default login and logout runmodes
  $authz->setup_runmodes;

  if ($rule = $authz->is_authz_runmode($self->get_current_runmode)) {
    # This runmode requires authorization
    my $authz_ok = ref($rule) eq 'CODE'   ? $rule->()
                 : ref($rule) eq 'ARRAY'  ? first { $self->authz->authorize($_) } @{$rule}
                 :                          $self->authz->authorize($rule);
    return $self->authz->redirect_to_forbidden
      unless ($authz_ok);
  }
}

=head2 redirect_to_forbidden

This method is be called during the prerun stage if
the current user is not authorized, and they are trying to
access an authz runmode.  It will redirect to the page
that has been configured as the forbidden page, based on the value
of FORBIDDEN_RUNMODE or FORBIDDEN_URL  If nothing is configured
then the default forbidden page will be used.

=cut

sub redirect_to_forbidden {
    my $self = shift;
    my $cgiapp = $self->cgiapp;
    my $config = $self->_config;

    if ($config->{FORBIDDEN_RUNMODE}) {
      $cgiapp->prerun_mode($config->{FORBIDDEN_RUNMODE});
    } elsif ($config->{FORBIDDEN_URL}) {
      $cgiapp->header_add(-location => $config->{FORBIDDEN_URL});
      $cgiapp->header_type('redirect');
      $cgiapp->prerun_mode('authz_dummy_redirect');
    } else {
      $cgiapp->prerun_mode('authz_forbidden');
    }
}

=head2 forbidden

This will return a forbidden page.  It checks the configuration to see if there
is a custom runmode or URL to redirect to, otherwise it calls the builtin
authz_forbidden runmode.

=cut

sub forbidden {
    my $self   = shift;
    my $cgiapp = $self->cgiapp;
    my $config = $self->_config;

    if ( $config->{FORBIDDEN_RUNMODE} ) {
        my $runmode = $config->{FORBIDDEN_RUNMODE};
        return $cgiapp->$runmode();
    }
    elsif ( $config->{FORBIDDEN_URL} ) {
        $cgiapp->header_add( -location => $config->{FORBIDDEN_URL} );
        $cgiapp->header_type('redirect');
        return;
    }
    else {
        return authz_forbidden( $self->cgiapp );
    }
}

=head1 CGI::Application RUNMODES

=head2 authz_forbidden

This runmode is provided if you do not want to create your own forbidden
runmode.  It will display a simple error page to the user.

=cut

sub authz_forbidden {
    my $self = shift;
    my $q    = $self->query;

    my $html = join(
        "\n",
        CGI::start_html(
            -title => 'Forbidden',
            #-style  => { -code => $self->auth->styles },
        ),
        CGI::h2('Forbidden'),
        CGI::p('You do not have permission to perform that action'),
        CGI::end_html(),
    );

    return $html;
}

=head2 authz_dummy_redirect

This runmode is provided for convenience when an external redirect needs
to be done.  It just returns an empty string.

=cut

sub authz_dummy_redirect {
    return '';
}

###
### Helper methods
###

sub _find_delegate_class {
    foreach my $class (@_) {
        $class->require && return $class;
    }
    return;
}

sub _config {
    my $self = shift;
    my $name = $self->{name};
    my $config;
    if ( ref $self->cgiapp ) {
        $config = $self->{__CAP_AUTHORIZATION_CONFIG} ||= $__CONFIG{$name}
            || {};
    }
    else {
        $__CONFIG{$name} ||= {};
        $config = $__CONFIG{$name};
    }
    return $config;
}

=head1 EXAMPLE

In a CGI::Application module:

  package MyCGIApp;

  use base qw(CGI::Application);
  use CGI::Application::Plugin::AutoRunmode;
  use CGI::Application::Plugin::Authentication;
  use CGI::Application::Plugin::Authorization;
  
  # Configure Authentication
  MyCGIApp->authen->config(
        DRIVER => 'Dummy',
  );
  MyCGIApp->authen->protected_runmodes(qr/^admin_/);

  # Configure Authorization (manages runmode authorization)
  MyCGIApp->authz->config(
      DRIVER => [ 'DBI',
          DBH         => $self->dbh,
          TABLES      => ['user', 'usergroup', 'group'],
          JOIN_ON     => 'user.id = usergroup.user_id AND usergroup.group_id = group.id',
          CONSTRAINTS => {
             'user.name'  => '__USERNAME__',
             'group.name' => '__GROUP__',
          }
      ],
  );
  MyCGIApp->authz->authz_runmodes(
     [a_runmode => 'a_group'],
     [qr/^admin_/ => 'admin'],
     [':all' => 'all_group'],
     [sub {my $rm = shift; return ($rm eq "dangerous_rm")} => 'super_group'],
  );

  # Configure second Authorization module using a named configuration
  __PACKAGE__->authz('dbaccess')->config(
      DRIVER => [ 'DBI',
          DBH   => $self->dbh,
          TABLES      => ['user', 'access'],
          JOIN_ON     => 'user.id = access.user_id',
          CONSTRAINTS => {
              'user.name'      => '__USERNAME__',
              'access.table'   => '__PARAM_1__',
              'access.item_id' => '__PARAM_2__'
          }
      ],
  );

  sub start : Runmode {
    my $self = shift;

  }

  sub admin_one : Runmode {
    my $self = shift;
    # The user will only get here if they are logged in and
    # belong to the admin group

  }

  sub admin_widgets : Runmode {
    my $self = shift;
    # The user will only get here if they are logged in and
    # belong to the admin group

    # Can this user edit this widget in the widgets table?
    my $widget_id = $self->query->param('widget_id');
    return $self->authz->forbidden unless $self->authz('dbaccess')->authorize(widgets => $widget_id);
    
  }


=head1 TODO

The module is definately in a usable state, but there are still some parts
missing that I would like to add in:

=over 4

=item provide easy methods for authorizing runmode access automatically

=item allow subroutine attributes to configure authorization for a runmode

=item write a tutorial/cookbook to include with the docs

=back


=head1 BUGS

This is alpha software and as such, the features and interface are subject to
change.  So please check the Changes file when upgrading.


=head1 SEE ALSO

L<CGI::Application::Plugin::Authentication>, L<CGI::Application>, perl(1)


=head1 AUTHOR

Cees Hek <ceeshek@gmail.com>

=head1 CREDITS

Thanks to SiteSuite (http://www.sitesuite.com.au) for funding the development
of this plugin and for releasing it to the world.


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2005, SiteSuite. All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY FOR THE
SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN OTHERWISE
STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES PROVIDE THE
SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND
PERFORMANCE OF THE SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE,
YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING WILL ANY
COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR REDISTRIBUTE THE
SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE TO YOU FOR DAMAGES,
INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING
OUT OF THE USE OR INABILITY TO USE THE SOFTWARE (INCLUDING BUT NOT LIMITED TO
LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR
THIRD PARTIES OR A FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE),
EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
DAMAGES.

=cut

1;
