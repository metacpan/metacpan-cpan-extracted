package Catalyst::Authentication::Store::FromSub::Hash;


use warnings;
use strict;
use vars qw/$VERSION/;
$VERSION = '0.09';

use Catalyst::Authentication::User::Hash;

sub new {
    my ( $class, $config, $app, $realm) = @_;

    bless { config => $config }, $class;
}

sub from_session {
    my ( $self, $c, $id ) = @_;

    # XXX? Don't use data in session because data maybe changed in model_class sub auth.
    # return $id if ref $id;
    
    my $id_field = $self->{config}->{id_field} || 'user_id';
    if (ref $id) {
        if ( exists $id->{$id_field} ) {
            return $self->find_user( { $id_field => $id->{$id_field}  }, $c );
        } else {
            return $id;
        }
    }

    $self->find_user( { $id_field => $id }, $c );
}

sub find_user {
    my ( $self, $userinfo, $c ) = @_;

    my $model_class = $self->{config}->{model_class};
    my $model = $c->model($model_class);
    
    my $user = $model->auth($c, $userinfo);
    return unless $user;

    if ( ref($user) eq 'HASH') {
        my $id_field = $self->{config}->{id_field} || 'user_id';
        my $id = $user->{ $id_field };
        $user->{id} ||= $id;
        return bless $user, "Catalyst::Authentication::User::Hash";
    } else {
        Catalyst::Exception->throw( "The user return by 'sub auth' must be a hash reference");
    }
    return $user;
}

sub user_supports {
    my $self = shift;

    my $model = $self->{config}->{model_class};

    $model->supports(@_);
}

## Backwards compatibility
#
# This is a backwards compatible routine.  get_user is specifically for loading a user by it's unique id
# find_user is capable of doing the same by simply passing { id => $id }  
# no new code should be written using get_user as it is deprecated.
sub get_user {
    my ( $self, $id ) = @_;
    $self->find_user({id => $id});
}

## backwards compatibility
sub setup {
    my $c = shift;

    $c->default_auth_store(
        __PACKAGE__->new( 
            $c->config->{authentication}, $c
        )
    );

    $c->NEXT::setup(@_);
}

1;
__END__

=head1 NAME

Catalyst::Authentication::Store::FromSub::Hash - A storage class for Catalyst Authentication using one Catalyst Model class (hash returned)

=head1 SYNOPSIS

    use Catalyst qw/Authentication/;

    __PACKAGE__->config->{authentication} = 
                    {  
                        default_realm => 'members',
                        realms => {
                            members => {
                                credential => {
                                    class => 'Password',
                                    password_field => 'password',
                                    password_type => 'clear'
                                },
                                store => {
                                    class => 'FromSub::Hash',
                                    model_class => 'UserAuth',
                                    id_field => 'user_id',
                                }
                            }
                        }
                    };

    # Log a user in:
    sub login : Global {
        my ( $self, $c ) = @_;
        
        $c->authenticate({  
                          username => $c->req->params->username,
                          password => $c->req->params->password,
                          }))
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

Catalyst::Authentication::Store::FromSub::Hash class provides 
access to authentication information by using a Catalyst Model sub auth.

In sub auth of the Catalyst model, we can use cache there. it would avoid the hit of db every request.

=head1 CONFIGURATION

The FromSub::Hash authentication store is activated by setting the store
config B<class> element to 'FromSub::Hash'.  See the 
L<Catalyst::Plugin::Authentication> documentation for more details on 
configuring the store.

The FromSub::Hash storage module has several configuration options


    __PACKAGE__->config->{authentication} = 
                    {  
                        default_realm => 'members',
                        realms => {
                            members => {
                                credential => {
                                    # ...
                                },
                                store => {
                                    class => 'FromSub::Hash',
                                    model_class => 'UserAuth',
                                    id_field => 'user_id',
                                }
                            }
                        }
                    };

    authentication:
      default_realm: 'members'
      password_hash_type: "clear"
      realms:
        members:
          credential:
            class: 'Password'
            password_field: 'password'
            password_type: "hashed"
            password_hash_type: "SHA-1"
          store:
            class: 'FromSub::Hash'
            model_class: "UserAuth"

=over 4

=item class

Class is part of the core Catalyst::Authentication::Plugin module, it
contains the class name of the store to be used.

=item user_class

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

It is a primary key in the hash return by sub auth. Default is 'user_id'

=back

=head1 USAGE 

The L<Catalyst::Authentication::Store::FromSub::Hash> storage module
is not called directly from application code.  You interface with it 
through the $c->authenticate() call.

=head1 EXAMPLES

=head2 Adv.

    # for login
    sub login : Global {
        my ( $self, $c ) = @_;
        
        $c->authenticate({  
                          username => $c->req->params->username,
                          password => $c->req->params->password,
                          status => [ 'active', 'registered' ],
                          }))
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

=head1 CODE USED IN LIVE

L<http://foorum.googlecode.com/svn/trunk/>

=head1 BUGS

None known currently, please email the author if you find any.

=head1 SEE ALSO

L<Catalyst::Plugin::Authentication>, L<Catalyst::Plugin::Authentication::Internals>, L<Catalyst::Plugin::Authorization::Roles>

=head1 AUTHOR

Fayland Lam, C<< <fayland at gmail.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2007 Fayland Lam, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
