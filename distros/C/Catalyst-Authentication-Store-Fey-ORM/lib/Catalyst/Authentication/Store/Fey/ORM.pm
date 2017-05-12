package Catalyst::Authentication::Store::Fey::ORM;
BEGIN {
  $Catalyst::Authentication::Store::Fey::ORM::VERSION = '0.001';
}
# ABSTRACT: A storage class for Catalyst Authentication using L<Fey::ORM>

use strict;
use warnings;
use Catalyst::Authentication::Store::Fey::ORM::User;

use base qw/Class::Accessor::Fast/;

BEGIN {
    __PACKAGE__->mk_accessors(qw/config/);
}

sub new {
    my ( $class, $config, $app ) = @_;

    my $self = {
        config => $config,
    };

    return bless $self, $class;
}

sub from_session {
    my ( $self, $c, $frozenuser ) = @_;

    my $user = Catalyst::Authentication::Store::Fey::ORM::User->new(
        $self->config,
        $c,
    );

    return $user->from_session($frozenuser, $c);
}

sub for_session {
    my ( $self, $c, $user ) = @_;

    return $user->for_session($c);
}

sub find_user {
    my ( $self, $authinfo, $c ) = @_;

    my $user = Catalyst::Authentication::Store::Fey::ORM::User->new(
        $self->config,
        $c,
    );

    return $user->load($authinfo, $c);
}

1;


=pod

=encoding utf-8

=head1 NAME

Catalyst::Authentication::Store::Fey::ORM - A storage class for Catalyst Authentication using L<Fey::ORM>

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    use Catalyst qw(
        Authentication
        Authorization::Roles
    );
    
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
                    class => 'Fey::ORM',
                    user_model => 'MyApp::User',
                    role_relation => 'roles',
                    role_field => 'rolename',
                }
            }
        }
    };
    
    # Log a user in:
    
    sub login : Global {
        my ( $self, $c ) = @_;
    
        $c->authenticate(
            {
                user_name => $c->req->params->{username},
                password  => $c->req->params->{password},
            }
        );
    }
    
    # verify a role
    
    if ( $c->check_user_roles( 'editor' ) ) {
        # do editor stuff
    }

=head1 DESCRIPTION

The L<Catalyst::Authentication::Store::Fey::ORM> class provides access to
authentication information stored in a database via L<Fey::ORM>.

=head1 METHODS

=head2 new ( $config, $app )

Constructs a new store object.

=head2 from_session ( $c, $frozenuser )

Revives a user from the session based on the info provided in C<$frozenuser>.
Currently treats $frozenuser as an id and retrieves a user
with a matching id.

=head2 for_session ( $c, $user )

Prepares a user to be stored in the session.
Currently returns the value of the user's id field
(as indicated by the 'id_field' config element).

=head2 find_user ( $authinfo, $c )

Finds a user using the information provided in the C<$authinfo> hashref
and returns the user, or undef on failure.
This is usually called from the Credential.
This translates directly to a call to
L<Catalyst::Authentication::Store::Fey::ORM::User>'s load() method.

=head1 CONFIGURATION

The L<Fey::ORM> storage module has several configuration options.

=over

=item class

=item user_model

=item id_field

=item role_column

=item role_field

=item role_relation

=item use_userdata_from_session

=back

=head1 AUTHOR

Keedi Kim - 김도형 <keedi@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Keedi Kim.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

