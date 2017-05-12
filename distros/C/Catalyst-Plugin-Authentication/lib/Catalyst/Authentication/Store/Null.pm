package Catalyst::Authentication::Store::Null;
use Moose;
use namespace::autoclean;

with 'MooseX::Emulate::Class::Accessor::Fast';

use Catalyst::Authentication::User::Hash;

__PACKAGE__->mk_accessors( qw( _config ) );

sub new {
    my ( $class, $config, $app, $realm ) = @_;
    bless { _config => $config }, $class;
}

sub for_session {
    my ( $self, $c, $user ) = @_;
    return $user;
}

sub from_session {
    my ( $self, $c, $user ) = @_;
    return $user;
}

sub find_user {
    my ( $self, $userinfo, $c ) = @_;
    return bless $userinfo, 'Catalyst::Authentication::User::Hash';
}

sub user_supports {
    my $self = shift;
    Catalyst::Authentication::User::Hash->supports(@_);
}

1;

__END__

=pod

=head1 NAME

Catalyst::Authentication::Store::Null - Null authentication store

=head1 SYNOPSIS

    use Catalyst qw(
        Authentication
    );

    __PACKAGE__->config( 'Plugin::Authentication' => {
        default_realm => 'remote',
        realms => {
            remote => {
                credential => {
                    class => 'TypeKey',
                    key_url => 'http://example.com/regkeys.txt',
                },
                store => {
                    class => 'Null',
                }
            }
        }
    });

=head1 DESCRIPTION

The Null store is a transparent store where any supplied user data is
accepted. This is mainly useful for remotely authenticating credentials
(e.g. TypeKey, OpenID) which may not be tied to any local storage. It also
helps facilitate integration with the Session plugin.

=head1 METHODS

=head2 new( )

Creates a new instance of the store.

=head2 for_session( )

Returns the user object passed to the method.

=head2 from_session( )

Returns the user object passed to the method.

=head2 find_user( )

Since this store isn't tied to any real set of users, this method just returns
the user info bless as a L<Catalyst::Authentication::User::Hash>
object.

=head2 user_supports( )

Delegates to L<Catalyst::Authentication::User::Hash>.

=cut
