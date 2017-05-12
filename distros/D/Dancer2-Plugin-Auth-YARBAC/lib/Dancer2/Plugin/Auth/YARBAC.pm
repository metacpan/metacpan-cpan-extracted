package Dancer2::Plugin::Auth::YARBAC;

use strict;
use warnings;

use Dancer2::Plugin;
use Module::Load;
use Carp;
use Try::Tiny;
use Data::Dumper;

our $VERSION = '0.011';

register logged_in_user => sub
{
    my $dsl  = shift;
    my $app  = $dsl->app;
    my $conf = plugin_setting();

    if ( $app->session->read('logged_in_user') && $app->session->read('logged_in_user_realm') )
    {
        return $dsl->retrieve_user;
    }

    return;
};

register hook_before_require_login => sub
{
    my $dsl     = shift;
    my $coderef = shift;
    my $app     = $dsl->app;
    my $conf    = plugin_setting();

    return _require_login( $dsl, $coderef, $conf, 'hook' );
};

register require_login => sub
{
    my $dsl     = shift;
    my $coderef = shift;
    my $app     = $dsl->app;
    my $conf    = plugin_setting();

    return _require_login( $dsl, $coderef, $conf );
};

register logout => sub
{
    my $dsl  = shift;
    my $app  = $dsl->app;
    my $conf = plugin_setting();

    $app->destroy_session;

    return $app->redirect( $conf->{after_logout} );
};

register login => sub
{
    my $dsl    = shift;
    my $params = shift;
    my $opts   = shift;
    my $app    = $dsl->app;
    my $conf   = plugin_setting();
    my $auth   = authenticate_user( $dsl, $params, $opts );

    if ( $auth->{success} && $auth->{realm} )
    {
        $app->session->write( logged_in_user       => $params->{username} );
        $app->session->write( logged_in_user_realm => $auth->{realm} );
        $app->session->delete('login_failed');

        my $return_url = $app->session->read('return_url');

        return $dsl->redirect( ( $return_url ) ? $return_url : $dsl->uri_for( $conf->{after_login} ) );
    }

    my $login_failed = $app->session->read( 'login_failed' );

    $app->session->write( login_failed => ++$login_failed );
    $dsl->debug( 'YARBAC ========> Setting login_failed: ' . $login_failed . ' times.' );

    return $dsl->redirect( $dsl->uri_for( $conf->{login_denied} ) . '?login_failed=' . $login_failed );
};

register authenticate_user => sub
{
    my $dsl    = shift;
    my $params = shift;
    my $opts   = shift;
    my $app    = $dsl->app;
    my $conf   = plugin_setting();
    my $auth   = 0;

    if ( ! $opts->{realm} )
    {
        for my $try_realm ( keys %{ $conf->{realms} } )
        {
            $opts->{realm} = $try_realm;
            $auth  = _try_auth_realm( $dsl, $params, $opts );
            last if ( $auth );
        }
    }
    else
    {
        $auth = _try_auth_realm( $dsl, $params, $opts );
    }

    return { success => $auth, realm => $opts->{realm} };
};

register generate_hash => sub
{
    my $dsl    = shift;
    my $params = shift;
    my $opts   = shift;
    my $app    = $dsl->app;
    my $conf   = plugin_setting();

    my $provider = _provider( $dsl, $conf, _try_realm( $app, $opts ) );

    return $provider->generate_hash( $params, $opts );
};

register password_strength => sub
{
    my $dsl    = shift;
    my $params = shift;
    my $opts   = shift;
    my $app    = $dsl->app;
    my $conf   = plugin_setting();

    my $provider = _provider( $dsl, $conf, _try_realm( $app, $opts ) );
    my $strength = $provider->password_strength( $params, $opts );

    if ( $strength->{error} )
    {
        for my $error ( @{ $strength->{errors} } )
        {
            $dsl->debug( "YARBAC ========> Password had the following error: error code is '$error->{code}' error message is '$error->{message}'" );
        }
    }

    return $strength;
};

register retrieve_user => sub
{
    my $dsl    = shift;
    my $params = _try_username( $dsl->app, shift );
    my $opts   = shift;
    my $app    = $dsl->app;
    my $conf   = plugin_setting();

    my $provider = _provider( $dsl, $conf, _try_realm( $app, $opts ) );

    return $provider->retrieve_user( $params, $opts );
};

register retrieve_role => sub
{
    my $dsl    = shift;
    my $params = shift;
    my $opts   = shift;
    my $app    = $dsl->app;
    my $conf   = plugin_setting();

    my $provider = _provider( $dsl, $conf, _try_realm( $app, $opts ) );

    return $provider->retrieve_role( $params, $opts );
};

register retrieve_group => sub
{
    my $dsl    = shift;
    my $params = shift;
    my $opts   = shift;
    my $app    = $dsl->app;
    my $conf   = plugin_setting();

    my $provider = _provider( $dsl, $conf, _try_realm( $app, $opts ) );

    return $provider->retrieve_group( $params, $opts );
};

register retrieve_permission => sub
{
    my $dsl    = shift;
    my $params = shift;
    my $opts   = shift;
    my $app    = $dsl->app;
    my $conf   = plugin_setting();
    
    my $provider = _provider( $dsl, $conf, _try_realm( $app, $opts ) );

    return $provider->retrieve_permission( $params, $opts );
};

register user_roles => sub
{
    my $dsl    = shift;
    my $params = _try_username( $dsl->app, shift );
    my $opts   = shift;
    my $app    = $dsl->app;
    my $conf   = plugin_setting();

    my $provider = _provider( $dsl, $conf, _try_realm( $app, $opts ) );

    return $provider->user_roles( $params, $opts );
};

register user_groups => sub
{
    my $dsl    = shift;
    my $params = _try_username( $dsl->app, shift );
    my $opts   = shift;
    my $app    = $dsl->app;
    my $conf   = plugin_setting();

    my $provider = _provider( $dsl, $conf, _try_realm( $app, $opts ) );

    return $provider->user_groups( $params, $opts );
};

register user_has_role => sub
{
    my $dsl    = shift;
    my $params = _try_username( $dsl->app, shift );
    my $opts   = shift;
    my $app    = $dsl->app;
    my $conf   = plugin_setting();

    my $provider = _provider( $dsl, $conf, _try_realm( $app, $opts ) );

    return $provider->user_has_role( $params, $opts );
};

register user_has_any_role => sub
{
    my $dsl    = shift;
    my $params = _try_username( $dsl->app, shift );
    my $opts   = shift;
    my $app    = $dsl->app;
    my $conf   = plugin_setting();

    my $provider = _provider( $dsl, $conf, _try_realm( $app, $opts ) );

    return $provider->user_has_any_role( $params, $opts );
};

register user_has_all_roles => sub
{
    my $dsl    = shift;
    my $params = _try_username( $dsl->app, shift );
    my $opts   = shift;
    my $app    = $dsl->app;
    my $conf   = plugin_setting();

    my $provider = _provider( $dsl, $conf, _try_realm( $app, $opts ) );

    return $provider->user_has_all_roles( $params, $opts );
};

register user_has_group => sub
{
    my $dsl    = shift;
    my $params = _try_username( $dsl->app, shift );
    my $opts   = shift;
    my $app    = $dsl->app;
    my $conf   = plugin_setting();

    my $provider = _provider( $dsl, $conf, _try_realm( $app, $opts ) );

    return $provider->user_has_group( $params, $opts );
};

register user_has_any_group => sub
{
    my $dsl    = shift;
    my $params = _try_username( $dsl->app, shift );
    my $opts   = shift;
    my $app    = $dsl->app;
    my $conf   = plugin_setting();

    my $provider = _provider( $dsl, $conf, _try_realm( $app, $opts ) );

    return $provider->user_has_any_group( $params, $opts );
};

register user_has_all_groups => sub
{
    my $dsl    = shift;
    my $params = _try_username( $dsl->app, shift );
    my $opts   = shift;
    my $app    = $dsl->app;
    my $conf   = plugin_setting();

    my $provider = _provider( $dsl, $conf, _try_realm( $app, $opts ) );

    return $provider->user_has_all_groups( $params, $opts );
};

register user_has_group_permission => sub
{
    my $dsl    = shift;
    my $params = _try_username( $dsl->app, shift );
    my $opts   = shift;
    my $app    = $dsl->app;
    my $conf   = plugin_setting();

    my $provider = _provider( $dsl, $conf, _try_realm( $app, $opts ) );

    return $provider->user_has_group_permission( $params, $opts );
};

register user_has_group_with_any_permission => sub
{
    my $dsl    = shift;
    my $params = _try_username( $dsl->app, shift );
    my $opts   = shift;
    my $app    = $dsl->app;
    my $conf   = plugin_setting();

    my $provider = _provider( $dsl, $conf, _try_realm( $app, $opts ) );

    return $provider->user_has_group_with_any_permission( $params, $opts );
};

register user_has_group_with_all_permissions => sub
{
    my $dsl    = shift;
    my $params = _try_username( $dsl->app, shift );
    my $opts   = shift;
    my $app    = $dsl->app;
    my $conf   = plugin_setting();

    my $provider = _provider( $dsl, $conf, _try_realm( $app, $opts ) );

    return $provider->user_has_group_with_all_permissions( $params, $opts );
};

register role_has_group => sub
{
    my $dsl    = shift;
    my $params = shift;
    my $opts   = shift;
    my $app    = $dsl->app;
    my $conf   = plugin_setting();

    my $provider = _provider( $dsl, $conf, _try_realm( $app, $opts ) );

    return $provider->role_has_group( $params, $opts );
};

register role_groups => sub
{
    my $dsl    = shift;
    my $params = shift;
    my $opts   = shift;
    my $app    = $dsl->app;
    my $conf   = plugin_setting();

    my $provider = _provider( $dsl, $conf, _try_realm( $app, $opts ) );

    return $provider->role_groups( $params, $opts );
};

register group_permissions => sub
{
    my $dsl    = shift;
    my $params = shift;
    my $opts   = shift;
    my $app    = $dsl->app;
    my $conf   = plugin_setting();

    my $provider = _provider( $dsl, $conf, _try_realm( $app, $opts ) );

    return $provider->group_permissions( $params, $opts );
};

register group_has_permission => sub
{
    my $dsl    = shift;
    my $params = shift;
    my $opts   = shift;
    my $app    = $dsl->app;
    my $conf   = plugin_setting();

    my $provider = _provider( $dsl, $conf, _try_realm( $app, $opts ) );

    return $provider->group_has_permission( $params, $opts );
};

register create_user => sub
{
    my $dsl    = shift;
    my $params = shift;
    my $opts   = shift;
    my $app    = $dsl->app;
    my $conf   = plugin_setting();

    my $provider = _provider( $dsl, $conf, _try_realm( $app, $opts ) );

    return $provider->create_user( $params, $opts );
};

register create_role => sub
{
    my $dsl    = shift;
    my $params = shift;
    my $opts   = shift;
    my $app    = $dsl->app;
    my $conf   = plugin_setting();

    my $provider = _provider( $dsl, $conf, _try_realm( $app, $opts ) );

    return $provider->create_role( $params, $opts );
};

register create_group => sub
{
    my $dsl    = shift;
    my $params = shift;
    my $opts   = shift;
    my $app    = $dsl->app;
    my $conf   = plugin_setting();

    my $provider = _provider( $dsl, $conf, _try_realm( $app, $opts ) );

    return $provider->create_group( $params, $opts );
};

register create_permission => sub
{
    my $dsl    = shift;
    my $params = shift;
    my $opts   = shift;
    my $app    = $dsl->app;
    my $conf   = plugin_setting();

    my $provider = _provider( $dsl, $conf, _try_realm( $app, $opts ) );
 
    return $provider->create_permission( $params, $opts );
};

register assign_user_role => sub
{
    my $dsl    = shift;
    my $params = shift;
    my $opts   = shift;
    my $app    = $dsl->app;
    my $conf   = plugin_setting();

    my $provider = _provider( $dsl, $conf, _try_realm( $app, $opts ) );

    return $provider->assign_user_role( $params, $opts );
};

register assign_role_group => sub
{
    my $dsl    = shift;
    my $params = shift;
    my $opts   = shift;
    my $app    = $dsl->app;
    my $conf   = plugin_setting();

    my $provider = _provider( $dsl, $conf, _try_realm( $app, $opts ) );

    return $provider->assign_role_group( $params, $opts );
};

register assign_group_permission => sub
{
    my $dsl    = shift;
    my $params = shift;
    my $opts   = shift;
    my $app    = $dsl->app;
    my $conf   = plugin_setting();

    my $provider = _provider( $dsl, $conf, _try_realm( $app, $opts ) );

    return $provider->assign_group_permission( $params, $opts );
};

register revoke_user_role => sub
{
    my $dsl    = shift;
    my $params = shift;
    my $opts   = shift;
    my $app    = $dsl->app;
    my $conf   = plugin_setting();

    my $provider = _provider( $dsl, $conf, _try_realm( $app, $opts ) );

    return $provider->revoke_user_role( $params, $opts );
};

register revoke_role_group => sub
{
    my $dsl    = shift;
    my $params = shift;
    my $opts   = shift;
    my $app    = $dsl->app;
    my $conf   = plugin_setting();

    my $provider = _provider( $dsl, $conf, _try_realm( $app, $opts ) );
 
    return $provider->revoke_role_group( $params, $opts );
};

register revoke_group_permission => sub
{
    my $dsl    = shift;
    my $params = shift;
    my $opts   = shift;
    my $app    = $dsl->app;
    my $conf   = plugin_setting();

    my $provider = _provider( $dsl, $conf, _try_realm( $app, $opts ) );

    return $provider->revoke_group_permission( $params, $opts );
};

register modify_user => sub
{
    my $dsl    = shift;
    my $params = shift;
    my $opts   = shift;
    my $app    = $dsl->app;
    my $conf   = plugin_setting();

    my $provider = _provider( $dsl, $conf, _try_realm( $app, $opts ) );

    return $provider->modify_user( $params, $opts );
};

register modify_role => sub
{
    my $dsl    = shift;
    my $params = shift;
    my $opts   = shift;
    my $app    = $dsl->app;
    my $conf   = plugin_setting();

    my $provider = _provider( $dsl, $conf, _try_realm( $app, $opts ) );

    return $provider->modify_role( $params, $opts );
};

register modify_group => sub
{
    my $dsl    = shift;
    my $params = shift;
    my $opts   = shift;
    my $app    = $dsl->app;
    my $conf   = plugin_setting();

    my $provider = _provider( $dsl, $conf, _try_realm( $app, $opts ) );

    return $provider->modify_group( $params, $opts );
};

register modify_permission => sub
{
    my $dsl    = shift;
    my $params = shift;
    my $opts   = shift;
    my $app    = $dsl->app;
    my $conf   = plugin_setting();

    my $provider = _provider( $dsl, $conf, _try_realm( $app, $opts ) );

    return $provider->modify_permission( $params, $opts );
};

register delete_user => sub
{
    my $dsl    = shift;
    my $params = shift;
    my $opts   = shift;
    my $app    = $dsl->app;
    my $conf   = plugin_setting();

    my $provider = _provider( $dsl, $conf, _try_realm( $app, $opts ) );

    return $provider->delete_user( $params, $opts );
};

register delete_role => sub
{
    my $dsl    = shift;
    my $params = shift;
    my $opts   = shift;
    my $app    = $dsl->app;
    my $conf   = plugin_setting();

    my $provider = _provider( $dsl, $conf, _try_realm( $app, $opts ) );
 
    return $provider->delete_role( $params, $opts );
};

register delete_group => sub
{
    my $dsl    = shift;
    my $params = shift;
    my $opts   = shift;
    my $app    = $dsl->app;
    my $conf   = plugin_setting();

    my $provider = _provider( $dsl, $conf, _try_realm( $app, $opts ) );

    return $provider->delete_group( $params, $opts );
};

register delete_permission => sub
{
    my $dsl    = shift;
    my $params = shift;
    my $opts   = shift;
    my $app    = $dsl->app;
    my $conf   = plugin_setting();

    my $provider = _provider( $dsl, $conf, _try_realm( $app, $opts ) );

    return $provider->delete_permission( $params, $opts );
};

register provider => sub
{
    my $dsl    = shift;
    my $params = shift;
    my $opts   = shift;
    my $app    = $dsl->app;
    my $conf   = plugin_setting();

    my $provider = _provider( $dsl, $conf, _try_realm( $app, $opts ) );

    return $provider;
};

sub _require_login
{
    my $dsl     = shift;
    my $coderef = shift;
    my $conf    = shift;
    my $hook    = shift;
    my $app     = $dsl->app;

    return sub
    {
        if ( ! $coderef || ref $coderef ne 'CODE' )
        {
            croak "Invalid require_login usage, please see documentation.";
        }

        if ( ! $app->session->read('logged_in_user') || ! $app->session->read('logged_in_user_realm') )
        {
            if ( defined $hook && $dsl->request->path_info =~ m/$conf->{no_login_required}/i )
            {
                return $coderef->();
            }

            $dsl->debug( 'YARBAC ========> User is not authenticated.' );

            if ( $dsl->request->path_info !~ m/^($conf->{login_denied}|$conf->{after_login})$/i )
            {
                $dsl->debug( 'YARBAC ========> Setting return_url: ' . $dsl->request->uri_base . $dsl->request->request_uri );
                $app->session->write( return_url => $dsl->request->uri_base . $dsl->request->request_uri );
            }

            return $dsl->redirect( $dsl->uri_for( $conf->{login_denied} ) );
        }

        return $coderef->();
    };
}

sub _try_auth_realm
{
    my $dsl    = shift;
    my $params = shift;
    my $opts   = shift;
    my $app    = $dsl->app;
    my $conf   = plugin_setting();

    return if ( ! defined $params->{username} || ! defined $params->{password} || ! defined $opts->{realm} );

    $dsl->debug( "YARBAC ========> Attempting to authenticate $params->{username} against realm $opts->{realm}." );

    my $provider = _provider( $dsl, $conf, $opts );

    if ( $provider->authenticate_user( $params, $opts ) )
    {
            $dsl->debug( "YARBAC ========> Realm $opts->{realm} accepted user $params->{username}." );

            return 1;
    }

    return;
}

sub _try_realm
{
    my $app  = shift;
    my $opts = shift;

    if ( ! defined $opts->{realm} )
    {
        $opts->{realm} = $app->session->read('logged_in_user_realm');
    }

    return $opts;
}

sub _try_username
{
    my $app    = shift;
    my $params = shift;

    if ( ! defined $params->{username} )
    {
        $params->{username} = $app->session->read('logged_in_user');
    }

    return $params;
}

{
    my $provider = {};

    sub _provider
    {
        my $dsl   = shift;
        my $app   = $dsl->app;
        my $conf  = shift;
        my $opts  = shift;

        return $provider->{ $opts->{realm} } if exists $provider->{ $opts->{realm} };

        my $settings = $conf->{realms}{ $opts->{realm} } || croak "Unknown realm $opts->{realm}";
        my $class    = $settings->{provider} || croak "No provider configured see: " . __PACKAGE__;

        if ( $class !~ m{::} )
        {
            $class = __PACKAGE__ . '::Provider::' . $settings->{provider};
        }

        try
        {
            load $class;
        }
        catch
        {
            croak "Failed to load provider: $class $_";
        };

        $dsl->debug( 'YARBAC ========> Loaded provider: ' . $class );

        $provider->{ $opts->{realm} } = $class->new( dsl => $dsl, app => $app, settings => $settings );

        my $require_methods = [  'authenticate_user', 'retrieve_user', 'retrieve_role', 'retrieve_group', 
                                 'retrieve_permission', 'user_roles', 'user_groups', 'user_has_role',
                                 'user_has_group_permission', 'role_has_group', 'group_permissions',
                                 'group_has_permission', 'create_user', 'create_role', 'create_group', 
                                 'create_permission', 'assign_user_role', 'assign_role_group',
                                 'assign_group_permission', 'revoke_user_role', 'revoke_role_group', 
                                 'revoke_group_permission', 'delete_user', 'delete_role', 'delete_group', 
                                 'delete_permission', 'modify_user', 'modify_role', 'modify_group',
                                 'modify_permission', 'user_has_group', 'user_has_any_group',
                                 'user_has_all_groups', 'user_has_group_with_any_permission',
                                 'user_has_group_with_all_permissions', 'user_has_any_role',
                                 'user_has_all_roles', 'role_groups',
                              ];

        for my $method ( @{ $require_methods } )
        {
            try
            {
                $provider->{ $opts->{realm} }->$method();
            }
            catch
            {
                croak "Provider $class does not contain the required method: $method.";
            };
        }

        return $provider->{ $opts->{realm} };
    }
}

register_plugin for_versions => [ 2 ] ;

1;

=pod

=encoding UTF-8

=head1 NAME

Dancer2::Plugin::Auth::YARBAC - Yet Another Role Based Access Control Framework

=head1 VERSION

version 0.011

=head1 SYNOPSIS

Configure the plugin to use the authentication provider class you would like to use. 
In this example we'll use the 'Database' provider:

  plugins:
  Auth::YARBAC:
    # Set redirect page after user logs out
    after_logout: '/login'
    # Set default redirect page after user logs in
    after_login: '/'
    # Set default redirect page if user fails login attempt
    login_denied: '/login'
    # Specify URL's that do not require authentication
    no_login_required: '^/login|/denied|/css|/images|/generate_hash'
    # Set your realms, one realm is required but you can have many
    realms:
      # Realm name
      test:
        # Our backend provider
        provider: 'Database'
        # Set the users table name (required by Database, default: users)
        users_table: 'users'
        # Set the users id column name (required by Database, default: id)
        users_id_column: 'id'
        # Set the users username column name (Database, default: username)
        users_username_column: 'username'
        # Set the users username column name (Database, default: password)
        users_password_column: 'password'
        # Password strength options optionally allows a check password strength
        password_strength:
           # Set the required minimum password score
          required_score: 25
          # Set minimum password length
          min_length: 6
          # Set maximum password length (good idea to avoid DDOS attacks)
          max_length: 32
          # If true, password must contain special characters
          special_characters: 1
          # If true, password must contain control characters
          control_characters: 1
          # If true, password must not be a repeating character
          no_repeating: 1
          # If true, password must contain a uppercase character
          upper_case: 1
          # If true, password must contain a lowercase character
          lower_case: 1
          # If true, password must contain a number
          numbers: 1

In your app the order of modules loaded is important. Ensure you set 
the session module before YARBAC. YARBAC doesn't care which session 
module you use so long as one is loaded. 
If you're using the L<Dancer2::Plugin::Auth::YARBAC::Provider::Database> 
backend provider ensure you've also loaded L<Dancer2::Plugin::Database> 
before YARBAC.

  package MyPackage;
     
  use Dancer2;
  use Dancer2::Plugin::Database;
  use Dancer2::Session::Cookie;
  use Dancer2::Plugin::Auth::YARBAC;

The configuration you provide will depend on the backend provider module 
you choose to use. In this example we're assuming the Database 
backend provider, see: 
L<Dancer2::Plugin::Auth::YARBAC::Provider::Database>.

=head1 DESCRIPTION

YARBAC is a role based user authentication and authorisation framework for Dancer2 apps. 
Designed with security and a medium to large user base in mind. 
This framework was heavily inspired by the excellent L<Dancer::Plugin::Auth::Extensible> 
framework which I'd highly recommend. 
YARBAC was designed to support secure password checking, enforced password hashing, 
multiple authentication realms and the ability to create your own backend provider. 
YARBAC was also designed to to be as flexible and as feature rich as possible 
in the hope that I'll never have to write RBAC code for Dancer again. :) 
While similar to Extensible in some ways, this framework has some significantly 
different approaches. 
These differences were born out of my own experiences writing RBAC code for various 
Dancer apps and finding myself always having to extend existing modules or 
starting from scratch or worse still, copy/paste my old code then reworking it. 
The major difference with YARBAC is that it tries to be a complete solution to the problem. 
However in order to be a little more flexible and feature rich in some areas it is also 
a little more opinionated in others. 
The main area of opinion in YARBAC is how it achieves role-based access control. 
YARBAC is structed with users, roles, groups and permissions. 
A user can have many roles but it might be a good idea in larger enviornments to only allow
a user to have one role and then assign that role have many groups. Think of a
role as being a role-group. Then there are groups which have many permissions.
A user can have one or more roles, a role can have one or more groups and groups
can have one or more permissions.
This means when deciding if a user is authorised we could require they be logged in, or have 
a specifc role, or specific group, or a specific group with a specific permission and so on. 
To put it another way, this design moves the access control down to the role-group 
relationship thus allowing one to quickly and easily see, assign or revoke permissions to a 
user even when dealing with a fairly complex authorisation environment. 

The logical flow of this design looks like so:

                                               +------------+
                                            -->| PERMISSION |
                                +-------+   |  +------------+
                             -->| GROUP |---- 
                 +------+    |  +-------+      +------------+
              -->| ROLE |----               -->| PERMISSION |
              |  +------+    |  +-------+   |  +------------+
              |              -->| GROUP |----
              |                 +-------+   |  +------------+
              |                             -->| PERMISSION |
  +------+    |                                +------------+
  | USER |----|                              
  +------+    |                                +------------+
              |                             -->| PERMISSION |
              |                 +-------+   |  +------------+
              |              -->| GROUP |---- 
              |  +------+    |  +-------+   |  +------------+
              -->| ROLE |----               -->| PERMISSION |
                 +------+    |  +-------+      +------------+
                             -->| GROUP |----
                                +-------+   |  +------------+
                                            -->| PERMISSION |
                                               +------------+

Of course just because there are users, roles, groups and permissions doesn't mean 
you have to use them. This module will happily function even if you just care 
about user authentication. Or perhaps you're just interested in users and roles,
this is also fine.

=head1 AUTHENTICATION BACKEND PROVIDERS

This framework allows the use of different backend providers.
At time of writing only the Database backend is available.

=over 4

=item L<Dancer2::Plugin::Auth::YARBAC::Provider::Database>

Authentication and authorisation using a database backend.

=back

Want to create your own provider backend? No problem, 
just write a Moo based module (or similar oo) and use it to extend
L<Dancer2::Plugin::Auth::YARBAC::Provider::Base> 
then implement the required methods and you're done.

=head1 CONTROLLING AUTHENTICATION ACCESS

There are three ways you can control authentication access to your app. 
One is using the keyword 'hook_before_require_login' which is a global 
check for all routes. 
This is handy if your app is mostly locked down with only a few exceptions. 
The exceptions can be specified in your apps config using the option 
'no_login_required' and putting in exempt routes here as a regex. 
The second option is to use the keyword 'require_login' which must be 
set on each route you wish authentication to be a requirement. 
This is handy when most of your app is open to the big wide 
world but you've got a few routes that need protecting. 
The third option is the keyword 'logged_in_user' which is
more manual but handy if the default behavour of URL
redirecting is getting in your way. 

=over

=item hook_before_require_login - Add on 'hook before', requires user to be logged in

  hook before => hook_before_require_login sub {
    
  };

If the user attempts to access a route that's not exempt via the config 
option regex 'no_login_require' then they will be redirected 
to whatever URL was specified in the apps config using the option 
'login_denied'.

=item require_login - Add to any route, requires user to be logged in

    get '/auth/is/required' => require_login sub {
        
    };

If the user attempts to access this route and they are not logged 
in they'll be redirected to whatever URL was specified 
in the apps config using the option 'login_denied'.

=item logged_in_user - Checks if user is logged in.

  get '/' => sub {
    unless ( logged_in_user ) {
        # user isn't logged in.
    }

    template 'index', {};
  };

If the user is logged in, the keyword 'logged_in_user' 
will return the logged in user as a hashref.
If the user is not logged in, it returns false.

=back

=head1 GRANTING AUTHENTICATION ACCESS

There are two ways one can authenticate a user.
The first is using the built in 'login' keyword.
This option will take care of the session management 
for you and redirect the user. Please note,
YARBAC requires you to use a Dancer2 session module
in your app but it doesn't care which one you choose.
The second is using the keyword 'authenticate_user'
which will only check if the username and password
was correct and then report back with a hashref.

=over

=item login - Attempts login and then redirects.

  any ['get', 'post'] => '/login' => sub {
    # Optionally set the realm:
    # return login( { username => params->{username}, 
    #                 password => params->{password} }, 
    #               { realm => params->{realm} } );
                  
    if ( params->{username} && params->{password} ) {
        return login( { username => params->{username},
                        password => params->{password} } );
    }
          
    template 'login', {};
  };

If the user authenticates successfully this will redirect the user to whatever 
was set via the config option 'after_login'. Unless the user was trying 
to access a specific route prior to authentication, in which case 
this will redirect the user to whatever route the user was trying to access. 
If the users attempt to authenticate fails this will redirect the user to 
whatever was set via the config option 'login_denied'. 
This also keeps track of the amount of failed authentication 
attempts by the user with the 'login_failed' param.

=item authenticate_user - Attempts auth and then returns a hashref

  get '/auth/user' => sub {
    # Optionally set the realm:
    # my $auth = authenticate_user( { username => params->{username}, 
    #                                 password => params->{password} }, 
    #                               { realm => params->{realm} } );

    my $auth = authenticate_user( { username => params->{username}, 
                                    password => params->{password} } );

    unless ( $auth->{success} ) {
        # User did not provide valid username or password.
    }

    #.......
  };

If the user authenticates successfully this will return a hashref with 
$auth->{success} being true and $auth->{realm} which will contain the 
realm name the user authenticated againts successfully. 
If the users attempt to authenticate fails this will return a hashref but
$auth->{realm} will be false.
That is all this keyword does so in order for a user to be correctly
authenticated with YARBAC the session name 'logged_in_user' will 
need to be set with the users username and 'logged_in_user_realm'
set with the users realm name.

=back

=head1 CONTROLLING AUTHORISATION BASED ACCESS

As previously stated, a user can have many roles, a role has one or 
more groups and a group has one or more permissions.
Therefore we can determine if a user should be granted access to 
a route or other material based on a number of requirements. 

=over

=item user_has_role - Checks if a user has a role

  get '/has/role' => sub { 
    # Optionally check user other than current logged in user:
    # user_has_role( { role_name => 'admin', username => 'sarah' } );
    #
    # Optionally user other realm than current logged in user:
    # user_has_role( { role_name => 'admin', }, { realm => 'admins' } );

    my $has_role = user_has_role( { role_name => 'admin' } );

    unless ( $has_role ) {
        # User doesn't have the role.
    }
    
    #....... 
  };

Keyword 'user_has_role' will check if the current logged in user
has the role specified. However one can specify a user to check by
adding 'username'. One can also check a different realm by
adding 'realm'. If the user has the role returns true otherwiese
returns false. 

=item user_has_any_role - Checks an arrayref of role names to see if the user has any

  get '/has/any/role' => sub { 
    # Optionally check user other than current logged in user:
    # user_has_any_role( { role_names => [ 'admin', 'managers' ], username => 'sarah' } );
    #
    # Optionally user other realm than current logged in user:
    # user_has_any_role( { role_names => [ 'admin', 'managers' ] }, { realm => 'admins' } );

    my $has_role = user_has_any_role( { role_names => [ 'admin', 'managers' ] } );

    unless ( $has_role ) {
        # User doesn't have the role.
    }
    
    #....... 
  };

Keyword 'user_has_any_role' will check if the current logged in user
has any of the roles specified. However one can specify a user to check by
adding 'username'. One can also check a different realm by
adding 'realm'. If the user has any of the roles returns true otherwise
returns false.

=item user_has_all_roles - Checks an arrayref of role names to see if the user has all

 get '/has/all/roles' => sub {
    # Optionally check user other than current logged in user:
    # user_has_all_roles( { role_names => [ 'admin', 'managers' ], 
    #                       username => 'gabby' } );
    #
    # Optionally use other realm than current logged in user:
    # user_has_all_roles( { role_names => [ 'admin', 'managers' ] }, 
    #                     { realm => 'admins' } );

    my $has_roles = user_has_all_roles( { role_names => [ 'admin', 'managers' ] } );

    unless ( $has_roles ) {
        # User doesn't have all of these roles.
    }

    #....... 
  };

Keyword 'user_has_all_roles' will check if the current logged in user
has all of the roles specified. However one can specify a user to check by
adding 'username'. One can also check a different realm by
adding 'realm'. If the user has all of the roles returns true otherwise
returns false.

=item user_has_group - Checks if a user has a group

  get '/has/group' => sub {
    # Optionally check user other than current logged in user:
    # user_has_group( { group_name => 'cs', username => 'ada' } );
    #
    # Optionally use other realm than current logged in user:
    # user_has_group( { group_name => 'cs'}, { realm => 'admins' } );

    my $has_group = user_has_group( { group_name => 'cs' } );

    unless ( $has_group ) {
        # User doesn't have the group.
    }
    
    #....... 
  };

Keyword 'user_has_group' will check if the current logged in user
has the group specified. However one can specify a user to check by
adding 'username'. One can also check a different realm by
adding 'realm'. If the user has the group returns true otherwise
returns false.

=item user_has_any_group - Checks an arrayref of group names to see if the user has any

 get '/has/any/group' => sub {
    # Optionally check user other than current logged in user:
    # user_has_any_group( { group_names => [ 'cs', 'ops' ], username => 'morris' } );
    #
    # Optionally use other realm than current logged in user:
    # user_has_any_group( { group_names => [ 'cs', 'ops' ] }, { realm => 'admins' } );

    my $has_groups = user_has_any_group( { group_names => [ 'cs', 'ops' ] } );

    unless ( $has_groups ) {
        # User doesn't have any of these groups.
    }

    #....... 
  };

Keyword 'user_has_any_group' will check if the current logged in user
has any of the groups specified. However one can specify a user to check by
adding 'username'. One can also check a different realm by
adding 'realm'. If the user has any of the groups returns true otherwise
returns false.

=item user_has_all_groups - Checks an arrayref of group names to see if the user has all

 get '/has/all/groups' => sub {
    # Optionally check user other than current logged in user:
    # user_has_all_groups( { group_names => [ 'cs', 'ops' ], 
    #                        username => 'gabby' } );
    #
    # Optionally use other realm than current logged in user:
    # user_has_all_groups( { group_names => [ 'cs', 'ops' ] }, 
    #                      { realm => 'admins' } );

    my $has_groups = user_has_all_groups( { group_names => [ 'cs', 'ops' ] } );

    unless ( $has_groups ) {
        # User doesn't have all of these groups.
    }

    #....... 
  };

Keyword 'user_has_all_groups' will check if the current logged in user
has all of the groups specified. However one can specify a user to check by
adding 'username'. One can also check a different realm by
adding 'realm'. If the user has all of the groups returns true otherwise
returns false.

=item user_has_group_permission - Checks if a user has a specific group with a permission

  get '/has/group/permission' => sub {
    # Optionally check user other than current logged in user:
    # user_has_group_permission( { group_name => 'cs', 
                                   permission_name => 'write', 
                                   username => 'Tess' } );
    #
    # Optionally use other realm than current logged in user:
    # user_has_group_permission( { group_name => 'cs', 
                                   permission_name => 'write' }, 
                                 { realm => 'admins' } );

    my $has_permission = user_has_group_permission( { group_name => 'cs', 
                                                      permission_name => 'write' } );

    unless ( $has_permission ) {
        # User doesn't have this group or group doesn't have this permission.
    }

    #.......
  };

Keyword 'user_has_group_permission' will check if the current logged in user
has specified group and that this group has a specified permission.
However one can specify a user to check by adding 'username'.
One can also check a different realm by adding 'realm'.
If the user has all of the groups returns true otherwise returns false.

=item user_has_group_with_any_permission - Checks if a user has a specific group with any permission

  get '/has/group/with/any/permission' => sub {
    # Optionally check user other than current logged in user:
    # user_has_group_with_any_permission( { group_name => 'cs', 
    #                                       permission_names => [ 'write', 'delete' ], 
    #                                       username => 'Jane' } );
    #
    # Optionally use other realm than current logged in user:
    # user_has_group_with_any_permission( { group_name => 'cs', 
    #                                       permission_names => [ 'write', 'delete' ] },
    #                                       { realm => 'admins' } );

    my $has_permission = user_has_group_with_any_permission( group_name => 'cs', 
                                                             permission_names => [ 'write', 'delete' ] );

    unless ( $has_permission ) {
        # User doesn't have this group or group doesn't have any of these permissions.
    }

    #.......
  };

Keyword 'user_has_group_with_any_permission' will check if the current logged in user
has the specified group and that this group has any of the specified permissions.
However one can specify a user to check by adding 'username'.
One can also check a different realm by adding 'realm'.
If the user has the group with any of the specified permissions returns true 
otherwise returns false.

=item user_has_group_with_all_permissions - Checks if a user has a specific group with all permissions

  get '/has/group/with/all/permissions' => sub {
    # Optionally check user other than current logged in user:
    # user_has_group_with_all_permissions( { group_name => 'cs', permission_names => [ 'write', 'delete' ], 
    #                                        username => 'matthew' } );
    #
    # Optionally use other realm than current logged in user:
    # user_has_group_with_all_permissions( { group_name => 'cs', permission_names => [ 'write', 'delete' ] }, 
    #                                      { realm => 'admins' } );

    my $has_permission = user_has_group_with_all_permissions( { group_name => 'cs', 
                                                                permission_names => [ 'write', 'delete' ] } );

    unless ( $has_permission ) {
        # User doesn't have this group or group doesn't have all of these permissions.
    }

    #.......
  };

Keyword 'user_has_group_with_all_permissions' will check if the current logged in user
has the specified group and that this group has all of the specified permissions.
However one can specify a user to check by adding 'username'.
One can also check a different realm by adding 'realm'.
If the user has the group with all of the specified permissions returns true 
otherwise returns false.

=item role_has_group - Checks if role has a group

  get '/role/has/group' => sub {
    # Optionally use other realm than current logged in user:
    # role_has_group( { role_name => 'admin', 
    #                   group_name => 'ops' }, 
    #                 { realm => 'admins' } );

    my $has_group = role_has_group( { role_name => 'admin', 
                                      group_name => 'ops' } );

    unless( $has_group ) {
        # Role doesn't have this group.
    }

    #.......
  };

Keyword 'role_has_group' will check if the specified role
has the group specified.
One can also check a different realm by adding 'realm'.
If the role has the group returns true otherwise
returns false. 

=item group_has_permission - Checks if group has a permission

  get '/group/has/permission' => sub {
    # Optionally use other realm than current logged in user:
    # group_has_permission( { group_name => 'cs', 
    #                         permission_name => 'write' }, 
    #                       { realm => 'admins' } );

    my $has_permission = group_has_permission( { group_name => 'cs', 
                                                 permission_name => 'write' } );
  
    unless {
        # group does not have this permission.
    }

    #.......    
  };

Keyword 'group_has_permission' will check if the specified group 
has the permission specified.
One can also check a different realm by adding 'realm'.
If the group has the permission returns true otherwise
returns false. 

=back

=head1 CREATING USERS, ROLES, GROUPS & PERMISSIONS

=over

=item create_user - Creates a user

  get '/create/user' => sub {
    # Optionally use other realm than current logged in user:
    # my $create = create_user( { username => 'Craig', 
    #                             password => 'pass' }, 
    #                           { realm => 'admins' } );
    # Oh, and don't ever use that password for real, obviously :)

    my $create = create_user( { username => 'Craig', 
                                password => 'pass' } );
    if ( $create ) {
        # success
    }

    #.......
  };

Keyword 'create_user' creates a new user. So long as your 
backend can match the hash key (i.e Database backend has a 
column name that matches the hash key) the data will be accepted. 
The users password is always hashed by default. 
One can also use a different realm by adding 'realm'.
If the user was created returns true otherwise reutrns false.

=item create_role - Creates a role

  get '/create/role' => sub {
    # Optionally use other realm than current logged in user:
    # my $create = create_role( { role_name => 'some role', 
    #                             description => 'blah blah' }, 
    #                           { realm => 'admins' } );
    #
    # description is optional
    my $create = create_role( { role_name => 'some role', 
                                description => 'blah blah' } );
    if ( $create ) {
        # success
    }

    #.......
  };

Keyword 'create_role' creates a new role.
One can also use a different realm by adding 'realm'.
One can also optionally give the role a description.
If the role was created returns true otherwise reutrns false.

=item create_group - Creates a group

  get '/create/group' => sub {
    # Optionally use other realm than current logged in user:
    # $create = create_group( { group_name => params->{group}, 
    #                           description => params->{description} }, 
    #                         { realm => 'admins' } );
    #
    # description is optional
    my $create = create_group( { group_name => params->{group}, 
                                 description => params->{description} } );
    if ( $create ) {
        # success
    }

    #.......
  };

Keyword 'create_group' creates a new group.
One can also use a different realm by adding 'realm'.
One can also optionally give the group a description.
If the group was created returns true otherwise reutrns false.

=item create_permission - Creates a permission

  get '/create/permission' => sub {
    # Optionally use other realm than current logged in user:
    # $create = create_permission( { permission_name => 'write', 
    #                                description => 'write stuff' }, 
    #                              { realm => 'admins' } );
    #
    # description is optional
    my $create = create_permission( { permission_name => 'write', 
                                      description => 'write stuff' } );
    if ( $create ) {
        # success
    }

    #.......
  };

Keyword 'create_permission' creates a new permission.
One can also use a different realm by adding 'realm'.
One can also optionally give the group a description.
If the permission was created returns true otherwise reutrns false.

=back

=head1 ASSIGN ROLES, GROUPS & PERMISSIONS

=over

=item assign_user_role - Assign user a role

  get '/assign/user/role' => sub {
    # Optionally use other realm than current logged in user:
    # my $assign = assign_role_group( { role_name => 'admin', 
    #                                   group_name => 'ops' }, 
    #                                 { realm => 'admins' } );

    my $assign = assign_user_role( { username => 'klaus', 
                                     role_name => 'admin' } );
    if ( $assign ) {
        # success
    }

    #.......
  };

Keyword 'assign_user_role' assigns the user a role.
One can also use a different realm by adding 'realm'.
If the role was assigned returns true otherwise reutrns false.

=item assign_role_group - Assign role a group

  get '/assign/role/group' => sub {
    # Optionally use other realm than current logged in user:
    # my $assign = assign_role_group( { role_name => 'admin', 
    #                                   group_name => 'ops' }, 
    #                                 { realm => 'admins' } );

    my $assign = assign_role_group( { role_name => 'admin', 
                                      group_name => 'ops' } );
    if ( $assign ) {
        # success
    }

    #.......
  };

Keyword 'assign_role_group' assigns the role a group.
One can also use a different realm by adding 'realm'.
If the group was assigned returns true otherwise reutrns false.

=item assign_group_permission

  get '/assign/group/permission' => sub {
    # Optionally use other realm than current logged in user:
    # my $assign = assign_group_permission( { group_name => 'ops', 
    #                                         permission_name => 'delete' }, 
    #                                       { realm => 'admins' } );

    my $assign = assign_group_permission( { group_name => 'ops', 
                                            permission_name => 'delete' } );
    if ( $assign ) {
        # success
    }

    #.......
  };

Keyword 'assign_group_permission' assigns the group a permission.
One can also use a different realm by adding 'realm'.
If the group was assigned returns true otherwise reutrns false.

=back

=head1 RETRIEVING ROLES, GROUPS & PERMISSIONS

=over

=item retrieve_user - Returns user as hashref

  get '/user' => sub {
    # Optionally use other realm than current logged in user:
    # my $user = retrieve_user( { username => params->{username} }, { realm => 'admin' } );
    my $user = retrieve_user( { username => params->{username} } );
                 
    # Optionally you can expand the YARBAC authorisation tree to give you all of the 
    # users roles, groups and permissions the user has displayed in a hierarchical way like so:
    my $user = retrieve_user( { username => params->{username} }, { expand => 1 } );
                           
    # This will add the hash key name 'yarbac' to your user hashref which has the tree
    # data which will look like:
    # $VAR1 = {
    #           'username' => 'sarah',
    #           'yarbac'   => { 'roles' => [ { role_name => 'role', groups => [ { group_name => 'group', permissions => [{}] }, ] }, ] },
    #         };
    # Although the expand call is a bit on the expensive side but can be helpful under certain conditions.
    #.......
  };

Keyword 'retrieve_user' returns the user with all attributes
has a hashref if the user exists. If the user does not exist
returns false.

=item retrieve_role - Returns role as hashref

  get '/role' => sub {
    # Optionally use other realm than current logged in user:
    # my $role = retrieve_role( { role_name => 'admin' }, { realm => 'admin' } );
            
    my $role = retrieve_role( { role_name => 'admin' } );
        
   #.......
  };

Keyword 'retrieve_role' returns the role with all attributes
has a hashref if the role exists. If the role does not exist
returns false.

=item retrieve_group - Returns group as hashref

  get '/group' => sub {
    # Optionally use other realm than current logged in user:
    # my $group = retrieve_group( { group_name => 'cs' }, { realm => 'admin' } );
            
    my $group = retrieve_role( { group_name => 'cs' } );
        
   #.......
  };

Keyword 'retrieve_group' returns the group with all attributes
has a hashref if the group exists. If the group does not exist
returns false.

=item retrieve_permission - Returns permission as hashref

  get '/permission' => sub {
    # Optionally use other realm than current logged in user:
    # my $perms = retrieve_permission( { permission_name => 'write' }, { realm => 'admin' } );
            
    my $perms = retrieve_permission( { permission_name => 'write' } );
        
   #.......
  };

Keyword 'retrieve_permission' returns the permission with all attributes
has a hashref if the permission exists. If the permission  does not exist
returns false.

=item role_groups - Returns role groups as arrayref

  get '/role/groups' => sub {
    # Optionally use other realm than current logged in user:
    # my $groups = role_groups( { role_name => params->{role} }, { realm => 'admin' } );
           
    my $groups = role_groups( { role_name => params->{role} } );
           
    #.......
  };

Keyword 'role_groups' returns the all of the role groups as an arrayref.
If the no groups exist returns false.

=item group_permissions - Returns group permissions as arrayref

  get '/group/permissions' => sub {
    # Optionally use other realm than current logged in user:
    # my $perms = group_permissions( { group_name => params->{group} }, { realm => 'admin' } );
       
    my $perms = group_permissions( { group_name => params->{group} }, { realm => 'admin' } );

    #.......
  };

Keyword 'group_permissions' returns the all of the group permissions as an arrayref.
If the no permissions exist returns false.

=item user_roles - Returns user roles as arrayref

  get '/user/roles' => sub {
    # Optionally use other realm than current logged in user:
    # my $role = user_roles( { username => params->{username} }, { realm => 'admin' } );
      
    my $role = user_roles( { username => params->{username} }, { realm => 'admin' } );
        
    #.......
  };

Keyword 'user_roles' returns the all of the users roles as an arrayref.
If the no roles exist returns false.

=item user_groups - Returns user groups as arrayref

  get '/user/groups' => sub {
    # Optionally use other realm than current logged in user:
    # my $groups = user_groups( { username => params->{username} }, { realm => 'admin' } );
          
    my $groups = user_groups( { username => params->{username} } );
            
    #.......
  };

Keyword 'user_groups' returns the all of the users groups as an arrayref.
If the no groups exist returns false.

=back

=head1 REVOKING ROLES, GROUPS & PERMISSIONS

=over

=item revoke_user_role - Revoke a role from a user

  get '/revoke/user/role' => sub {
    # Optionally use other realm than current logged in user:
    # revoke_user_role( { username => 'sam', role_name => 'admin' }, { realm => 'admins' } );
    #
    # Optionally use other realm than current logged in user:
    my $revoke = revoke_user_role( { username => 'sam', role_name => 'admin' } );
       
    if ( $revoke ) {
        # success
    }

    #.......
  };

Keyword 'revoke_user_role' revokes the role from the user.
One can also use a different realm by adding 'realm'.
If the role was revoked returns true otherwise reutrns false.

=item revoke_role_group - Revoke a group from a role

  get '/revoke/role/group' => sub {
    # Optionally use other realm than current logged in user:
    # my $revoke = revoke_role_group( { role_name => 'admin', 
    #                                   group_name => 'marketing' }, 
    #                                 { realm => 'admins' } );

    my $revoke = revoke_role_group( { role_name => 'admin', 
                                      group_name => 'marketing' } );
       
    if ( $revoke ) {
        # success
    }

    #.......
  };

Keyword 'revoke_role_group' revokes the group from the role.
One can also use a different realm by adding 'realm'.
If the group was revoked returns true otherwise reutrns false.

=item revoke_group_permission - Revoke a permission from a group

  get '/revoke/group/permission' => sub {
    # Optionally use other realm than current logged in user:
    # my $revoke = revoke_group_permission( { group_name => 'cs', 
    #                                         permission_name => 'write' }, 
    #                                       { realm => 'admins' } );

    my $revoke = revoke_group_permission( { group_name => 'cs', 
                                            permission_name => 'write' } );
       
    if ( $revoke ) {
        # success
    }

    #.......
  };

Keyword 'revoke_group_permission' revokes the permission from the group
One can also use a different realm by adding 'realm'.
If the permssion was revoked returns true otherwise reutrns false.

=back

=head1 MODIFYING USERS, ROLES, GROUPS & PERMISSIONS

=over

=item modify_user - Modify existing user

  get '/modify/user' => sub {
    # Optionally use other realm than current logged in user:
    # my $modify = modify_user( { username => 'sarah',
    #                             password => 'my new pass' }, 
    #                           { id => '1', realm =>'admins' } );
    # password is optional
    my $modify = modify_user( { username => 'sarah',
                                password => 'my new pass' },
                              { id => '1' } );
    # This is annoying backwards when compared to 
    # Dancer::Plugin::Database, sorry about that.
    # One could argue this isn't necessary.
     
    if ( $modify ) {
        # success
    }

    #.......
  };

Keyword 'modify_user' modifies an existing user. So long as your 
backend can match the hash key (i.e Database backend has a 
column name that matches the hash key) the data will be accepted. 
The users password is optional but is always hashed by default.
One can also use a different realm by adding 'realm'.
If you wish to modify the users username then you'll need to
provide the user id else you can just provide the username or id.
If the user was modified returns true otherwise reutrns false.

=item modify_role - Modify existing role

  get '/modify/role' => sub {
    # Optionally use other realm than current logged in user:
    # my $modify = modify_role( { role_name => 'admin',
    #                             description => 'blah' },
    #                           { id => '1', realm => 'admins' } );
    #
    # description is optional
    my $modify = modify_role( { role_name => 'admin',
                                description => 'blah' },
                              { id => '1' } );
    # This is annoying backwards when compared to 
    # Dancer::Plugin::Database, sorry about that.
    # One could argue this isn't necessary.
      
    if ( $modify ) {
        # success
    }

    #.......
  };

Keyword 'modify_role' modifies an existing role.
One can also use a different realm by adding 'realm'.
If you wish to modify the role name then you'll need to
provide the role id else you just provide the role name or id.
One can also optionally give the role a description.
If the role was created returns true otherwise reutrns false.

=item modify_group - Modify existing group

  get '/modify/group' => sub {
    # Optionally use other realm than current logged in user:
    # my $modify = modify_group( { group_name => 'who cares',
    #                              description => 'tired of writing' }, 
    #                            { id => '1', realm => 'admins' } );
    #
    # description is optional
    my $modify = modify_group( { group_name => 'who cares',
                                 description => 'tired of writing' },
                               { id => '1' } );
    # This is annoying backwards when compared to 
    # Dancer::Plugin::Database, sorry about that.
    # One could argue this isn't necessary.
     
    if ( $modify ) {
        # success
    }

    #.......
  };

Keyword 'modify_group' modifies an existing group.
One can also use a different realm by adding 'realm'.
One can also optionally give the group a description.
If you wish to modify the group name then you'll need to
provide the group id else you just provide the group name or id.
If the group was modified returns true otherwise reutrns false.

=item modify_permission - Modify existing permission

  get '/modify/permission' => sub {
    # Optionally use other realm than current logged in user:
    # my $modify = modify_permission( { permission_name => 'write',
    #                                   description => 'meh' }, 
    #                                 { id => '1', realm => 'admins' } );
    #
    # description is optional
    my $modify = modify_permission( { permission_name => 'write',
                                      description => 'meh' },
                                    { id => '1' } );
    # This is annoying backwards when compared to 
    # Dancer::Plugin::Database, sorry about that.
    # One could argue this isn't necessary.
            
    if ( $modify ) {
        # success
    }

    #.......
  };

Keyword 'modify_permission' modifies an existing permission.
One can also use a different realm by adding 'realm'.
One can also optionally give the group a description.
If you wish to modify the permission name then you'll need to
provide the permission id else you just provide the permission name or id.
If the permission was modified returns true otherwise reutrns false.

=back

=head1 DELETEING USERS, ROLES, GROUPS & PERMISSIONS

=over

=item delete_user - Deletes user

  get '/delete/user' => sub {
    # Optionally use other realm than current logged in user:
    # my $delete = delete_user( { username => 'robin' }, 
    #                           { realm => 'admins' } );

    my $delete = delete_user( { username => 'robin' } );
              
    if ( $delete ) {
        # success
    }
              
    #.......
  };

Keyword 'delete_user' deletes the user specified by username.
One can also use a different realm by adding 'realm'.
If the user was deleted returns true otherwise returns false.

=item delete_role - Deletes role

  get '/delete/role' => sub {
    # Optionally use other realm than current logged in user:
    # my $delete = delete_role( { role_name => 'some role' }, 
    #                           { realm => 'admins' } );

    my $delete = delete_role( { role_name => 'some role' } );
              
    if ( $delete ) {
        # success
    }
              
    #.......
  };

Keyword 'delete_role' deletes the role specified by role name.
One can also use a different realm by adding 'realm'.
If the role was deleted returns true otherwise returns false.

=item delete_group - Deletes group

  get '/delete/group' => sub {
    # Optionally use other realm than current logged in user:
    # my $delete = delete_group( { group_name => 'some group' }, 
    #                            { realm => 'admins' } );

    my $delete = delete_group( { group_name => 'some group' } );
              
    if ( $delete ) {
        # success
    }
              
    #.......
  };

Keyword 'delete_group' deletes the group specified by group name.
One can also use a different realm by adding 'realm'.
If the group was deleted returns true otherwise returns false.

=item delete_permission - Deletes permission

  get '/delete/permission' => sub {
    # Optionally use other realm than current logged in user:
    # my $delete = delete_permission( { permission_name => 'some perm' }, 
    #                                 { realm => 'admins' } );

    my $delete = delete_permission( { permission_name => 'some perm' } );
              
    if ( $delete ) {
        # success
    }
              
    #.......
  };

Keyword 'delete_permission' deletes the permission 
specified by permission name. 
One can also use a different realm by adding 'realm'.
If the group was deleted returns true otherwise returns false.

=back

=head1 PASSWORDS AND HASHING

=over

=item generate_hash - Turn clear text into hash

  get '/generate_hash' => sub {
    # Optionally use other realm than current logged in user:
    # my $hash = generate_hash( { password => params->{password} }, { realm => 'test' } );
             
    my $hash = generate_hash( { password => params->{password} } );
             
    #....... 
  };

Keyword 'generate_hash' will turn your clear text password into the 
a SHA2 512bit hash with salt using L<Crypt::PBKDF2>.
Which is the default hashing method employed with YARBAC.
However, when creating or modify a user with YARBAC 
you don't need to call on this as hashing happens automatically.

=item password_strength - Checks a clear text password for its strength

  post '/password_strength' => sub {
    # Optionally use other realm than current logged in user:
    my $strength = password_strength( { password => params->{password} }, { realm => 'admin' } );
                
    my $strength = password_strength( { password => params->{password} } );
   
    # returns a hashref like so:
    # { score => $score, error => $error, errors => \@errors }
    # Depending on what is enabled in your config, 
    # possile error codes are in error arrayref are: 
    #{ code => 1, message => 'Password is empty' }
    #{ code => 2, message => 'Password is too short' }
    #{ code => 3, message => 'Password is too long' }
    #{ code => 4, message => 'Password must contain special characters' }
    #{ code => 5, message => 'Password must contain control characters' }
    #{ code => 6, message => 'Password must not be repeating characters' }
    #{ code => 7, message => 'Password must contain at least one uppercase character' }
    #{ code => 8, message => 'Password must contain at least one lowercase character' }
    #{ code => 9, message => 'Password must contain at least one number character' }
    #{ code => 10, message => 'Password scored x points, must score at least y points' }

    unless ( $strength->{error} ) {
        # Looks like the password strength isn't strong enough.
    }
    
    #.......             
  };

Keyword 'password_strength' will check a clear text password for its strength.
This is not enforced when creating or updating a user via YARBAC 
thus is completely optional. 
If errors are found returns a hashref with 'error' as true otherwise 'error' 
is false.

=back

=head1 MISCELLANEOUS

=over

=item provider - Returns the backend provider object

  get '/provider' => sub {
    my $provider = provider();
    #.......         
  };

Keyword 'provider' returns the backend provider object.
Wouldn't recommend it without a good reason.

=back

=head1 AUTHOR

Sarah Fuller <sarah@averna.id.au>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Sarah Fuller.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: Yet Another Role Based Access Control Framework

