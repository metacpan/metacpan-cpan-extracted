# ABSTRACT: DEPRECATED! Please use L<Dancer::Plugin::Auth::RBAC>.

package Dancer::Plugin::Authorize;
BEGIN {
  $Dancer::Plugin::Authorize::VERSION = '1.110720';
}
use strict;
use warnings;
use Dancer qw/:syntax/;
use Dancer::Plugin;

BEGIN {
    warn "THIS MODULE IS DEPRECATED. PLEASE USE Dancer::Plugin::Auth::RBAC";
};

our $settings = {};

register auth => sub { 
    $settings = plugin_setting;
    return Dancer::Plugin::Authorize->new(@_) 
};

register authd => sub {
    if ( session('user') ) {
        if ( session('user')->{id} ) {
            return true;
        }
    }
    return false;
};


sub new {
    my $class = shift;
    my @credentials = @_;
    
    my $credentialsClass =
    __PACKAGE__ . "::Credentials::" . $settings->{credentials}->{class};
    {
        no warnings 'redefine';
        $credentialsClass =~ s/::/\//g;
        require "$credentialsClass.pm";
        $credentialsClass =~ s/\//::/g;
    }
    
    my $self = {};
    bless $self, $class;
    
    # return $credentialsClass->new
    # unless scalar @credentials;
    
    my $user = session('user');
    
    if ($user) {
        # reset authentication errors
        $user->{error} = [];
    }
    else {
        # initialize user session object
        $user = {
            id    => undef,
            name  => undef,
            login => undef,
            roles => [],
            error => []
        };
    }
    
    session 'user' => $user;
    
    #return $credentialsClass->new->authorize($settings->{credentials}->{options}, @credentials)
    #? $self : undef;
    
    $credentialsClass->new->authorize($settings->{credentials}->{options}, @credentials);
    return $self;
}

sub asa {
    my $self = shift;
    my $permissionsClass =
    __PACKAGE__ . "::Permissions::" . $settings->{permissions}->{class};
    {
        no warnings 'redefine';
        $permissionsClass =~ s/::/\//g;
        require "$permissionsClass.pm";
        $permissionsClass =~ s/\//::/g;
    }
    return $permissionsClass->new->subject_asa($settings->{permissions}->{options}, @_);
}

sub can {
    my $self = shift;
    my $permissionsClass =
    __PACKAGE__ . "::Permissions::" . $settings->{permissions}->{class};
    {
        no warnings 'redefine';
        $permissionsClass =~ s/::/\//g;
        require "$permissionsClass.pm";
        $permissionsClass =~ s/\//::/g;
    }
    return $permissionsClass->new->subject_can($settings->{permissions}->{options}, @_);
}

sub roles {
    my $self = shift;
    if (@_) {
        my $user = session('user');
        if ($user) {
            if ($user->{id}) {
                push @{$user->{roles}}, @_;
                session 'user' => $user;
            }
        }
    }
    else {
        my $user = session('user');
        if ($user) {
            if ($user->{id}) {
                return $user->{roles};
            }
        }
    }
}

sub errors {
    my $self = shift;
    return @{ session('user')->{error} };
}

sub revoke {
    my $self = shift;
    return session 'user' => {};
}

register_plugin;

1;

__END__
=pod

=head1 NAME

Dancer::Plugin::Authorize - DEPRECATED! Please use L<Dancer::Plugin::Auth::RBAC>.

=head1 VERSION

version 1.110720

=head1 SYNOPSIS

    post '/login' => sub {
        
        my $auth = auth(params->{user}, params->{pass});
        if (! $auth->errors) {
        
            if ($auth->asa('guest')) {
                ...
            }
            
            if ($auth->can('manage_accounts', 'create')) {
                ...
            }
            
        }
        else {
            print $auth->errors;
        }
    
    };

Note! The authentication framework relies heavily on your choosen session engine,
please remember to set that appropiately in your application configuration file.

=head1 DESCRIPTION

Dancer::Plugin::Authorize is an authentication framework and role-based access
control system. As a role-based access control system Dancer::Plugin::Authorize
can be complex but will give you the most flexibilty over all other access
control philosophies.

The Dancer::Plugin::Authorize plugin provides your application with the ability
to easily authenticate and restrict access to specific users and groups by providing
a tried and tested RBAC (role-based access control) system. Dancer::Plugin::Authorize
provides this level of sophistication with minimal configuration.

Dancer::Plugin::Authorize exports the auth() and authd() keywords:

    $auth = auth($login, $pass)     # new authorization instance
    $auth->asa($role)               # check if the authenticated user has the specified role
    $auth->can($operation)          # check if the authenticated user has permission
    $auth->can($operation, $action) # to perform a specific action
    $auth->roles(@roles)            # get or set roles for the current logged in user
    $auth->errors()                 # authentication errors if any
    $auth->revoke()                 # revoke authorization (logout)
    
    return authd()                  # is the current user authorized?

The Dancer::Plugin::Authorize authentication framework relies on the
L<Dancer::Plugin::Authorize::Credentials> namespace to do the actual
authentication, and likewise relies on the L<Dancer::Plugin::Authorize::Permissions>
namespace to handle access control. The following configuration example is based on
L<Dancer::Plugin::Authorize::Credentials::Config> and L<Dancer::Plugin::Authorize::Permissions::Config>.
This framework also ship with L<Dancer::Plugin::Authorize::Credentials::SQLite>,
L<Dancer::Plugin::Authorize::Credentials::MySQL>, L<Dancer::Plugin::Authorize::Credentials::PostrgeSQL>
which are arguably easier to setup and utilize.

=head1 DEPRECATION WARNING

This module has been deprecated in favor of L<Dancer::Plugin::Auth::RBAC> which
is currently a complete fork but will be maintained and improved instead of this
one.

In due time this will probably be deleted.

=head1 CONFIGURATION

    plugins:
      Authorize:
        credentials:
          class: Config
          options:
            accounts:
              user01:
                password: foobar
                roles:
                  - guest
                  - user
              user02:
                password: barbaz
                roles:
                  - admin
        permissions:
          class: Config
          options:
            control:
              admin:
                permissions:
                  manage accounts:
                    operations:
                      - view
                      - create
                      - update
                      - delete
              user:
                permissions:
                  manage accounts:
                    operations:
                      - view
                      - create
              guests:
                permissions:
                  manage accounts:
                    operations:
                      - view

=head1 AUTHOR

  Al Newkirk <awncorp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by awncorp.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

