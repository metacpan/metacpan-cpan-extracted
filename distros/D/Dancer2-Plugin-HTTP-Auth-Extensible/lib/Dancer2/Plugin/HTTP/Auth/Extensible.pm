package Dancer2::Plugin::HTTP::Auth::Extensible;

use warnings;
use strict;

use Carp;
use Dancer2::Plugin;
use Class::Load qw(try_load_class);

use HTTP::Headers::ActionPack::Authorization;
use HTTP::Headers::ActionPack::WWWAuthenticate;

our $VERSION = '0.121';


=head1 NAME

Dancer2::Plugin::HTTP::Auth::Extensible - extensible authentication framework for Dancer2 apps

=head1 DESCRIPTION

A user authentication and authorisation framework plugin for Dancer2 apps.

Makes it easy to require a user to be logged in to access certain routes,
provides role-based access control, and supports various authentication
methods/sources (config file, database, Unix system users, etc).

Designed to support multiple authentication realms and to be as extensible as
possible, and to make secure password handling easy (the base class for auth
providers makes handling C<RFC2307>-style hashed passwords really simple, so you
have no excuse for storing plain-text passwords).


=head1 SYNOPSIS

Configure the plugin to use the authentication provider class you wish to use:

  plugins:
        HTTP::Auth::Extensible:
            realms:
                users:
                    provider: Example
                    ....

The configuration you provide will depend on the authentication provider module
in use.  For a simple example, see
L<Dancer2::Plugin::Auth::Extensible::Provider::Config>.

Define that a user must be logged in and have the proper permissions to 
access a route:

    get '/secret' => http_require_role Confidant => sub { tell_secrets(); };

Define that a user must be logged in to access a route - and find out who is
logged in with the C<logged_in_user> keyword:

    get '/users' => http_require_authentication sub {
        my $user = http_authenticated_user;
        return "Hi there, $user->{username}";
    };

=head1 AUTHENTICATION PROVIDERS

This framework builds on top of L<Dancer2::Plugin::Auth::Extensible>. For a
full explenation of the providers check that manual.

For flexibility, that authentication framework uses simple authentication
provider classes, which implement a simple interface and do whatever is required
to authenticate a user against the chosen source of authentication.

For an example of how simple provider classes are, so you can build your own if
required or just try out this authentication framework plugin easily, 
see L<Dancer2::Plugin::Auth::Extensible::Provider::Example>.

That framework supplies the following providers out-of-the-box:

=over 4

=item L<Dancer2::Plugin::Auth::Extensible::Provider::Unix>

Authenticates users using system accounts on Linux/Unix type boxes

=item L<Dancer2::Plugin::Auth::Extensible::Provider::Database>

Authenticates users stored in a database table

=item L<Dancer2::Plugin::Auth::Extensible::Provider::Config>

Authenticates users stored in the app's config

=back

Need to write your own?  Just subclass
L<Dancer2::Plugin::Auth::Extensible::Provider::Base> and implement the required
methods, and you're good to go!

=head1 CONTROLLING ACCESS TO ROUTES

Keywords are provided to check if a user is logged in / has appropriate roles.

=over

=item http_require_authentication - require the user to be authenticated

    get '/dashboard' => http_require_authentication sub { .... };

If the user can not be authenticated, they will be recieve a HTTP response
status of C</401 Not Authorized>. Remember, it should actualy say 'Not
Authenticated'.

Optionally, a realm name can be specified as an extra argument:

    get 'outer_space'
        => http_require_authentication 'outer_space'
        => sub { .... };

=item http_require_role - require the user to have a specified role

    get '/beer' => http_require_role BeerDrinker => sub { ... };

Requires that the user can be authenticated as a user who has the specified
role.  If the user can not be authenticated, they will get a C<401 Unautorized>
response. If they are logged in, but do not have the required role, they will
recieve a C<403 Forbidden> response.

=item http_require_any_roles - require the user to have one of a list of roles

    get '/drink' => require_any_role [qw(BeerDrinker VodaDrinker)] => sub {
        ...
    };

Same as L<http_require_role> except that a user has any one (or more) of the
roles listed.

=item require_all_roles - require the user to have all roles listed

    get '/foo' => require_all_roles [qw(Foo Bar)] => sub { ... };

Same as L<http_require_role> except that a user has all of the roles listed.

=back

=head2 Replacing the Default C< 401 > and C< 403 > Pages


=head2 Keywords

=over

=item http_require_authentication

Used to wrap a route which requires a user can be authenticated to access
it.

    get '/secret' => http_require_authentication sub { .... };
    get '/secret' => http_require_authentication 'realm-name' sub { .... };

=cut

sub http_require_authentication {
    my $dsl = shift;
    my $realm = (@_ == 2) ? shift : http_default_realm($dsl);
    my $coderef = shift;

    return sub {
        if (!$coderef || ref $coderef ne 'CODE') {
            warn "Invalid http_require_authentication usage, please see docs";
        }
        
        my $user = http_authenticated_user($dsl, $realm);
        if (!$user) {
#           $dsl->execute_hook('http_authentication_required', $coderef);
#           # TODO: see if any code executed by that hook set up a response
            $dsl->header('WWW-Authenticate' =>
                qq|@{[ http_default_scheme($dsl) ]} realm="$realm"|
            );
            $dsl->status(401); # Unauthorized
            return
                qq|Authentication required to access realm: |
            .   qq|'$realm'|;
        }
        return $coderef->($dsl);
    };
}

register http_require_authentication  => \&http_require_authentication;
register http_requires_authentication  => \&http_require_authentication;

=item require_role

Used to wrap a route which requires a user can be authenticated with the
specified role in order to access it.

    get '/beer' => require_role BeerDrinker => sub { ... };
    get '/beer' => require_role BeerDrinker 'realm-name' => sub { ... };

You can also provide a regular expression, if you need to match the role using a
regex - for example:

    get '/beer' => http_require_role qr/Drinker$/ => sub { ... };

=cut

sub http_require_role {
    return _build_wrapper(@_, 'single');
}

register http_require_role  => \&http_require_role;
register http_requires_role => \&http_require_role;

=item http_require_any_role

Used to wrap a route which requires a user can be authenticated with any
one (or more) of the specified roles in order to access it.

    get '/foo' => http_require_any_role [qw(Foo Bar)] => sub { ... };
    get '/foo' => http_require_any_role [qw(Foo Bar)] 'realm-name' => sub { ... };

=cut

sub http_require_any_role {
    return _build_wrapper(@_, 'any');
}

register http_require_any_role  => \&http_require_any_role;
register http_requires_any_role => \&http_require_any_role;

=item http_require_all_roles

Used to wrap a route which requires a user can be authenticated with all
of the roles listed in order to access it.

    get '/foo' => http_require_all_roles [qw(Foo Bar)] => sub { ... };
    get '/foo' => http_require_all_roles [qw(Foo Bar)] 'realm-name' => sub { ... };

=cut

sub http_require_all_roles {
    return _build_wrapper(@_, 'all');
}

register http_require_all_roles  => \&http_require_all_roles;
register http_requires_all_roles => \&http_require_all_roles;


sub _build_wrapper {
    my $dsl = shift;
    my $require_role = shift;
    my $realm = (@_ == 3) ? shift : http_default_realm($dsl);
    my $coderef = shift;
    my $mode = shift;

    return sub {
        if (!$coderef || ref $coderef ne 'CODE') {
            warn "Invalid http_require_authentication usage, please see docs";
        }
        
        my $user = http_authenticated_user($dsl, $realm);
        if (!$user) {
#           $dsl->execute_hook('http_authentication_required', $coderef);
#           # TODO: see if any code executed by that hook set up a response
            $dsl->header('WWW-Authenticate' =>
                qq|@{[ http_default_scheme($dsl) ]} realm="$realm"|
            );
            $dsl->status(401); # Unauthorized
            return
                qq|Authentication required to access realm: |
            .   qq|'$realm'|;
        }
        
        my @role_list = ref $require_role eq 'ARRAY' 
            ? @$require_role
            : $require_role;
        my $role_match;
        if ($mode eq 'single') {
            for (user_roles($dsl)) {
                $role_match++ and last if _smart_match($_, $require_role);
            }
        } elsif ($mode eq 'any') {
            my %role_ok = map { $_ => 1 } @role_list;
            for (user_roles($dsl)) {
                $role_match++ and last if $role_ok{$_};
            }
        } elsif ($mode eq 'all') {
            $role_match++;
            for my $role (@role_list) {
                if (!user_has_role($dsl, $role)) {
                    $role_match = 0;
                    last;
                }
            }
        }
        if (!$role_match) {

#           $dsl->execute_hook('http_permission_denied', $coderef);
#           # TODO: see if any code executed by that hook set up a response
            $dsl->status(403); # Forbidden
            return
                qq|Permission denied for resource: |
            .   qq|'@{[ $dsl->request->path ]}'|;
        }
        
        # We're happy with their roles, so go head and execute the route
        # handler coderef.
        return $coderef->($dsl);

    }; # return sub
} # _build_wrapper



=item authenticated_user

Returns a hashref of details of the currently authenticated user, if there is one.

The details you get back will depend upon the authentication provider in use.

=cut

sub http_authenticated_user {
    my $dsl = shift;
    my $realm = shift || http_default_realm($dsl);
    
    if ( http_authenticate_user($dsl, $realm) ) { # undef unless http_authenticate_user
        my $provider = auth_provider($dsl, http_realm($dsl));
        return $provider->get_user_details(
            http_username($dsl),
            http_realm($dsl)
        );
    } else {
        return;
    }
}
register http_authenticated_user => \&http_authenticated_user;

=item user_has_role

Check if a user has the role named.

By default, the currently-logged-in user will be checked, so you need only name
the role you're looking for:

    if (user_has_role('BeerDrinker')) { pour_beer(); }

You can also provide the username to check; 

    if (user_has_role($user, $role)) { .... }

=cut

sub user_has_role {
    my $dsl = shift;
    my $session = $dsl->app->session;

    my ($username, $want_role);
    if (@_ == 2) {
        ($username, $want_role) = @_;
    } else {
        $username  = http_username($dsl);
        $want_role = shift;
    }

    return unless defined $username;

    my $roles = user_roles($dsl, $username);

    for my $has_role (@$roles) {
        return 1 if $has_role eq $want_role;
    }

    return 0;
}
register user_has_role => \&user_has_role;

=item user_roles

Returns a list of the roles of a user.

By default, roles for the currently-logged-in user will be checked;
alternatively, you may supply a username to check.

Returns a list or arrayref depending on context.

=cut

sub user_roles {
    my ($dsl, $username, $realm) = @_;
    my $session = $dsl->app->session;

    $username = http_username($dsl) unless defined $username;

    my $search_realm = ($realm ? $realm : '');

    my $roles = auth_provider($dsl, $search_realm)->get_user_roles($username);
    return unless defined $roles;
    return wantarray ? @$roles : $roles;
}
register user_roles => \&user_roles;


=item authenticate_user

Usually you'll want to let the built-in authentication handling code deal with
authenticating users, but in case you need to do it yourself, this keyword
accepts a username and password, and optionally a specific realm, and checks
whether the username and password are valid.

For example:

    if (authenticate_user($username, $password)) {
        ...
    }

If you are using multiple authentication realms, by default each realm will be
consulted in turn.  If you only wish to check one of them (for instance, you're
authenticating an admin user, and there's only one realm which applies to them),
you can supply the realm as an optional third parameter.

In boolean context, returns simply true or false; in list context, returns
C<($success, $realm)>.

=cut

sub http_authenticate_user {
    my $dsl = shift;
    my $realm = shift || http_default_realm($dsl);
    
    http_realm_exists($dsl, $realm);

    unless ($dsl->request->header('Authorization')) {
        return wantarray ? (0, undef) : 0;
    }
#   my ($username, $password) = $dsl->request->headers->authorization_basic;
    
    my $auth
    = HTTP::Headers::ActionPack::Authorization::Basic
      ->new_from_string($dsl->request->header('Authorization'));
    my $username = $auth->username;
    my $password = $auth->password;
    
    # TODO For now it only does Basic authentication
    #      Once we have Digest and others, it needs to choose itself
    
    my @realms_to_check = $realm ? ($realm) : (keys %{ plugin_setting->{realms} });

    for my $realm (@realms_to_check) { # XXX we only should have 1 ????
        $dsl->app->log ( debug  => "Attempting to authenticate $username against realm $realm");
        my $provider = auth_provider($dsl, $realm);
        if ($provider->authenticate_user($username, $password)) {
            $dsl->app->log ( debug => "$realm accepted user $username");
            $dsl->vars->{'http_username'} = $username;
            # don't do `http_username($dsl, $username)`, SECURITY BREACH
            $dsl->vars->{'http_realm'   } = $realm;
            # don't do `http_username($dsl, $username)`, SECURITY BREACH
            return wantarray ? ($username, $realm) : $username;
        }
    }

    # If we get to here, we failed to authenticate against any realm using the
    # details provided. 
    # TODO: allow providers to raise an exception if something failed, and catch
    # that and do something appropriate, rather than just treating it as a
    # failed login.
    return wantarray ? (0, undef) : 0;
}

register http_authenticate_user => \&http_authenticate_user;

sub http_default_realm {
    my $dsl = shift;
    
    if (1 == keys %{ plugin_setting->{realms} }) {
        return (keys %{ plugin_setting->{realms} })[0]; # only the first key in scalar context
    }
    if (exists plugin_setting->{default_realm} ) {
        return plugin_setting->{default_realm};
    }

    die
        qq|Internal Server Error: |
    .   qq|"multiple realms without default"|;
    
    return;
    
} # http_default_realm

#register http_default_realm => \&http_default_realm;

sub http_realm_exists {
    my $dsl = shift;
    my $realm = shift || http_default_realm($dsl);

    unless (grep {$realm eq $_} keys %{ plugin_setting->{realms} }) {
        die
            qq|Internal Server Error: |
        .   qq|"required realm does not exist: '$realm'"|;
    }
    
    return $realm;
    
} # http_realm_exists

#register http_realm_exists => \&http_realm_exists;


sub http_default_scheme {
    my $dsl = shift;
    my $realm = shift || http_default_realm($dsl);

    http_realm_exists($dsl, $realm);
    
    my $scheme;
    
    if (exists plugin_setting->{realms}->{$realm}->{scheme} ) {
        $scheme = plugin_setting->{realms}->{$realm}->{scheme};
    }
    else {
        $scheme = "Basic";
    }
    
    return $scheme;
    
} # http_default_schema

#register http_default_scheme => \&http_default_scheme;


sub http_scheme_known {
    my $dsl = shift;
    my $scheme = shift;

    unless (grep $scheme eq $_, ('Basic', 'Digest')) {
        warn
            qq|unknown scheme '$scheme'!|;
        return;
    }
    
    return $scheme;
    
} # http_scheme_known

#register http_scheme_known => \&http_scheme_known;

=item http_username - gets or sets the name of the authenticated user

WARNING: setting the username will issue a "SECURITY BREACH" warning. You
rarely want to impersonate another user.

    $my username = http_username;
    http_username('new name');
    http_username 'new name';

If not inside an authenticated route (there is no authenticated user),
C< http_username > returns undef.

=cut

sub http_username {
    my $dsl = shift;
    
    unless ( exists $dsl->vars->{http_username} ) {
        $dsl->app->log( warning =>
            qq|'http_username' should only be used in an authenticated route|
        );
    }
    
    if (@_ == 1) { # CAUTION: use with care
        $dsl->vars->{http_username} = shift;
        my $message
        =   qq|POTENTIONAL SECURITY BREACH: |
        .   qq|"impersonating different user: '|
        .   $dsl->vars->{http_username}
        .   qq|'"|;
        warn $message;
        $dsl->app->log ( warning => $message );
    }
    
    return unless exists $dsl->vars->{http_username};
    return $dsl->vars->{http_username};
    
} # http_username

register http_username => \&http_username;

=item http_realm - gets or sets the real of the current request

WARNING: setting the realm will issue a "SECURITY BREACH" warning. You
rarely want to switch to another realm

    $my realm = http_realm;
    http_realm('new name');
    http_realm 'new name';

If not inside an authenticated route (there is no authenticated user),
C< http_realm > returns undef.

=cut

sub http_realm {
    my $dsl = shift;
    
    unless ( exists $dsl->vars->{http_realm} ) {
        $dsl->app->log( warning =>
            qq|'http_realm' should only be used in an authenticated route|
        );
    }
    
    if (@_ == 1) { # CAUTION: use with care
        $dsl->vars->{http_realm} = shift;
        my $message
        =   qq|POTENTIONAL SECURITY BREACH: |
        .   qq|"switching to different realm: '|
        .   $dsl->vars->{http_realm}
        .   qq|'"|;
        warn $message;
        $dsl->app->log ( warning => $message );
    }
    
    return unless exists $dsl->vars->{http_realm};
    return $dsl->vars->{http_realm};
    
} # http_realm

register http_realm => \&http_realm;

=back

=head2 SAMPLE CONFIGURATION

In your application's configuation file:

    plugins:
        HTTP::Auth::Extensible:
            # Set to 1 if you want to disable the use of roles (0 is default)
            disable_roles: 0
            # After /login: If no return_url is given: land here ('/' is default)
            user_home_page: '/user'
            # After /logout: If no return_url is given: land here (no default)
            exit_page: '/'
            
            # List each authentication realm, with the provider to use and the
            # provider-specific settings (see the documentation for the provider
            # you wish to use)
            realms:
                realm_one:
                    provider: Database
                        db_connection_name: 'foo'
            
            default_realm: realm_xxx
            # If there is more than one realm, is needed if no 'realm' is
            # specified in http_requires_authentication.

B<Please note> that you B<not have to> have a session provider configured.  The 
authentication framework B<does not> require sessions in order to track information about 
the currently logged in user.

=cut

{
# Given a realm, returns a configured and ready to use instance of the provider
# specified by that realm's config.
my %realm_provider;
sub auth_provider {
    my $dsl = shift;
    my $realm = shift || http_default_realm($dsl);
   
    http_realm_exists($dsl, $realm); # can be in void, it dies when false

    # First, if we already have a provider for this realm, go ahead and use it:
    return $realm_provider{$realm} if exists $realm_provider{$realm};

    # OK, we need to find out what provider this realm uses, and get an instance
    # of that provider, configured with the settings from the realm.
    my $realm_settings = plugin_setting->{realms}->{$realm}
        or die "Invalid realm $realm";
    my $provider_class = $realm_settings->{provider}
        or die "No provider configured - consult documentation for "
            . "Dancer2::Plugin::Auth::Extensible";

    if ($provider_class !~ /::/) {
        $provider_class = "Dancer2::Plugin::Auth::Extensible" . "::Provider::$provider_class";
    }
    my ($ok, $error) = try_load_class($provider_class);

    if (! $ok) {
        die "Cannot load provider $provider_class: $error";
    }

    return $realm_provider{$realm} = $provider_class->new($realm_settings);
}
}

register_hook qw(http_authentication_required http_permission_denied);
register_plugin for_versions => [qw(1 2)];


# Given a class method name and a set of parameters, try calling that class
# method for each realm in turn, arranging for each to receive the configuration
# defined for that realm, until one returns a non-undef, then return the realm which
# succeeded and the response.
# Note: all provider class methods return a single value; if any need to return
# a list in future, this will need changing)
sub _try_realms {
    my ($method, @args);
    for my $realm (keys %{ plugin_setting->{realms} }) {
        my $provider = auth_provider($realm);
        if (!$provider->can($method)) {
            die "Provider $provider does not provide a $method method!";
        }
        if (defined(my $result = $provider->$method(@args))) {
            return $result;
        }
    }
    return;
}

on_plugin_import {
    my $dsl = shift;
    my $app = $dsl->app;

};


# Replacement for much maligned and misunderstood smartmatch operator
sub _smart_match {
    my ($got, $want) = @_;
    if (!ref $want) {
        return $got eq $want;
    } elsif (ref $want eq 'Regexp') {
        return $got =~ $want;
    } elsif (ref $want eq 'ARRAY') {
        return grep { $_ eq $got } @$want;
    } else {
        carp "Don't know how to match against a " . ref $want;
    }
}




=head1 AUTHOR

Theo van Hoesel, C<< <Th.J.v.Hoesel at THEMA-MEDIA dot nl> >>

HTTP Autneticate implementation based on:

David Precious, C<< <davidp at preshweb.co.uk> >>

Dancer2 port of Dancer::Plugin::Auth::Extensible by:

Stefan Hornburg (Racke), C<< <racke at linuxia.de> >>

=head1 BUGS / FEATURE REQUESTS

This is an early version; there may still be bugs present or features missing.

This is developed on GitHub - please feel free to raise issues or pull requests
against the repo at:
L<https://github.com/THEMA-MEDIA/Dancer2-Plugin-HTTP-Auth-Extensible>



=head1 ACKNOWLEDGEMENTS

Valuable feedback on the early design of this module came from many people,
including Matt S Trout (mst), David Golden (xdg), Damien Krotkine (dams),
Daniel Perrett, and others.

Configurable login/logout URLs added by Rene (hertell)

Regex support for require_role by chenryn

Support for user_roles looking in other realms by Colin Ewen (casao)

LDAP provider added by Mark Meyer (ofosos)

Config options for default login/logout handlers by Henk van Oers (hvoers)

=head1 LICENSE AND COPYRIGHT


Copyright 2014 THEMA-MEDIA, Th.J. van Hoesel

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Dancer2::Plugin::HTTP::Auth::Extensible
