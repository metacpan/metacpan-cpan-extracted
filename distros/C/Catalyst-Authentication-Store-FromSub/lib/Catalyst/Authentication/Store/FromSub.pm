package Catalyst::Authentication::Store::FromSub;
our $VERSION = '0.01';

use warnings;
use strict;

# ABSTRACT: A storage class for Catalyst Authentication using one Catalyst Model class

sub new {
    my ( $class, $config, $app ) = @_;

    # load User or Object module
    my $user_type = $config->{user_type};
    if ( $user_type eq 'Hash' ) {
        Catalyst::Utils::ensure_class_loaded(
            'Catalyst::Authentication::User::Hash');
        $config->{user_type} = 'Catalyst::Authentication::User::Hash';
    }
    elsif ( $user_type eq 'Object' ) {
        Catalyst::Utils::ensure_class_loaded(
            'Catalyst::Authentication::FromSub::User::Object');
        $config->{user_type} =
          'Catalyst::Authentication::FromSub::User::Object';
    }
    else {
        Catalyst::Utils::ensure_class_loaded($user_type);
    }

    bless { config => $config }, $class;
}

sub from_session {
    my ( $self, $c, $id ) = @_;

 # Don't use data in session because data maybe changed in model_class sub auth.
 # return $id if ref $id;

    my $id_field = $self->{config}->{id_field} || 'id';
    if ( ref $id ) {
        if ( exists $id->{$id_field} ) {
            return $self->find_user( { $id_field => $id->{$id_field} }, $c );
        }
        else {
            return $id;
        }
    }

    $self->find_user( { $id_field => $id }, $c );
}

sub for_session {
    my ( $self, $c, $user ) = @_;

    return $user->for_session($c);
}

sub find_user {
    my ( $self, $userinfo, $c ) = @_;

    my $config      = $self->{config};
    my $model_class = $config->{model_class};
    my $model       = $c->model($model_class);

    my $user = $model->auth( $c, $userinfo );
    return unless $user;

    if ( $config->{user_type} eq 'Catalyst::Authentication::User::Hash' ) {
        return $config->{user_type}->new($user);
    }
    else {
        return $config->{user_type}
          ->new( { user => $user, storage => $self }, $c );
    }
}

sub user_supports {
    my $self = shift;

    # this can work as a class method on the user class
    $self->{config}->{user_type}->supports(@_);
}

1;
__END__

=head1 NAME

Catalyst::Authentication::Store::FromSub - A storage class for Catalyst Authentication using one Catalyst Model class

=head1 VERSION

version 0.01

=head1 SYNOPSIS

    use Catalyst qw/Authentication/;

    __PACKAGE__->config->{authentication} = {  
        default_realm => 'members',
        realms => {
            members => {
            credential => {
                class => 'Password',
                password_field => 'password',
                password_type => 'clear'
            },
            store => {
                class => 'FromSub', # or 'Object'
                user_type => 'Hash',
                model_class => 'UserAuth',
                id_field => 'user_id',
            }
        }
    } };

    # Log a user in:
    sub login : Global {
        my ( $self, $c ) = @_;

        $c->authenticate( {  
            username => $c->req->params->username,
            password => $c->req->params->password,
        } );
    }

    package MyApp::Model::UserAuth; # map with model_class in config above
    use base qw/Catalyst::Model/;
    use strict;

    sub auth { # sub name needs to be 'auth'
        my ($self, $c, $userinfo) = @_;

        my $where;
        if (exists $userinfo->{user_id}) { # restore from session (id_field => 'user_id')
            $where = { user_id => $userinfo->{user_id} };
        } elsif (exists $userinfo->{username}) { # from authenticate
            $where = { username => $userinfo->{username} };
        } else { return; }

        # deal with cache
        # if (my $val = $c->cache->get($key) {
        #     return $val;
        # } else {
            my $user = $c->model('TestApp')->resultset('User')->search( $where )->first;
            $user = $user->{_column_data}; # hash
        #     $c->cache->set($key, $user);
        # }

        return $user;
    }

=head1 DESCRIPTION

Catalyst::Authentication::Store::FromSub class provides 
access to authentication information by using a Catalyst Model sub B<auth>.

In sub auth of the Catalyst model, we can use cache there (or do some complicated code). it would avoid the hit of db every request.

=head2 CONFIGURATION

The FromSub authentication store is activated by setting the store
config B<class> element to 'FromSub'.  See the 
L<Catalyst::Plugin::Authentication> documentation for more details on 
configuring the store.

The FromSub storage module has several configuration options

    __PACKAGE__->config->{authentication} = {  
        default_realm => 'members',
        realms => {
            members => {
                credential => {
                    # ...
                },
                store => {
                    class => 'FromSub',
                    user_type => 'Object',
                    model_class => 'UserAuth',
                    id_field => 'user_id',
                }
            }
        }
    };

    authentication:
      default_realm: 'members'
      realms:
        members:
          credential:
            class: 'Password'
          store:
            class: 'FromSub'
            user_type: 'Object'
            model_class: "UserAuth"

=over 4

=item class

Class is part of the core Catalyst::Authentication::Plugin module, it
contains the class name of the store to be used. it must be 'FromSub' here.

=item user_type

'Hash' or 'Object', depends on the return value in sub auth, B<REQUIRED>.

=item model_class

Contains the class name (as passed to $c->model()) of Catalyst.  This config item is B<REQUIRED>.

=item id_field

For restore from session, we pass { $id_field => $c->session->{__user}->{$id_field} } to sub auth, so be sure you deal with this $userinfo in sub auth like

    sub auth { # sub name needs to be 'auth'
        my ($self, $c, $userinfo) = @_;

        my $where;
        if (exists $userinfo->{user_id}) { # restore from session (id_field => 'user_id')
            $where = { user_id => $userinfo->{user_id} };
        } elsif (exists $userinfo->{username}) { # from authenticate
            $where = { username => $userinfo->{username} };
        } else { return; }

It is a primary key return by sub auth. Default as 'id'

=back

=head2 USAGE 

The L<Catalyst::Authentication::Store::FromSub> storage module
is not called directly from application code.  You interface with it 
through the $c->authenticate() call.

=head2 EXAMPLES

=head3 Adv.

    # for login
    sub login : Global {
        my ( $self, $c ) = @_;

        $c->authenticate( {  
            username => $c->req->params->username,
            password => $c->req->params->password,
            status => [ 'active', 'registered' ],
        } );
    }

    sub is_admin : Global {
        my ( $self, $c ) = @_;

        # use Set::Object in C::P::A::Roles
        eval {
            if ( $c->assert_user_roles( qw/admin/ ) ) {
                $c->res->body( 'ok' );
            }
        };
        if ($@) {
            $c->res->body( 'failed' );
        }
    }

    package MyApp::Model::UserAuth; # map with model_class in config above
    use base qw/Catalyst::Model/;
    use strict;

    sub auth {
        my ($self, $c, $userinfo) = @_;

        my ($where, $cache_key);
        if (exists $userinfo->{user_id}) {
            $where = { user_id => $userinfo->{user_id} };
            $cache_key = 'global|user|user_id=' . $userinfo->{user_id};
        } elsif (exists $userinfo->{username}) {
            $where = { username => $userinfo->{username} };
            $cache_key = 'global|user|username=' . $userinfo->{username};
        } else { return; }

        my $user;
        if (my $val = $c->cache->get($cache_key) {
            $user = $val;
        } else {
            $user = $c->model('TestApp')->resultset('User')->search( $where )->first;
            $user = $user->{_column_data}; # hash to cache
            # get user roles
            my $role_rs = $c->model('TestApp')->resultset('UserRole')->search( {
                user => $user->{id}
            } );
            while (my $r = $role_rs->next) {
                my $role = $c->model('TestApp')->resultset('Role')->find( {
                    id => $r->roleid
                } );
                push @{$user->{roles}}, $role->role;
            }
            # $user = {
            #     'roles' => [
            #         'admin',
            #         'user'
            #     ],
            #    'status' => 'active',
            #    'session_data' => undef,
            #    'username' => 'jayk',
            #    'email' => 'j@cpants.org',
            #    'password' => 'letmein',
            #    'id' => '3'
            #}
            $c->cache->set($cache_key, $user);
        }

        # validate status
        if ( exists $userinfo->{status} and ref $userinfo->{status} eq 'ARRAY') {
            unless (grep { $_ eq $user->{status} } @{$userinfo->{status}}) {
                return;
            }
        }

        return $user;
    }

=head2 SEE ALSO

L<Catalyst::Plugin::Authentication>, L<Catalyst::Plugin::Authentication::Internals>, L<Catalyst::Plugin::Authorization::Roles>

=head1 AUTHOR

  Fayland Lam <fayland@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Fayland Lam.

This is free software; you can redistribute it and/or modify it under
the same terms as perl itself.

=pod 
