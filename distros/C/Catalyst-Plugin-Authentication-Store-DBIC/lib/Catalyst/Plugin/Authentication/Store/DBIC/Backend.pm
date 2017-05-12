package Catalyst::Plugin::Authentication::Store::DBIC::Backend;

use strict;
use warnings;
use base qw/Class::Accessor::Fast/;

sub new {
    my ( $class, $config ) = @_;

    my $uc = $config->{auth}{catalyst_user_class};
    eval "require $uc";
    die $@ if $@;

    $config->{auth}{user_field} = [ $config->{auth}{user_field} ]
        if !ref $config->{auth}{user_field};
    $config->{authz}{role_field} ||= 'role';
    $config->{authz}{user_role_user_field} ||= $config->{auth}{user_field}->[0];

    bless { %{$config} }, $class;
}

sub from_session {
    my ( $self, $c, $id ) = @_;

    return $id if ref $id;
    
    return $self->{auth}{catalyst_user_class}->new( $id, { %{$self} } );

}

sub get_user {
    my ( $self, $id, @rest ) = @_;

    my $user = $self->{auth}{catalyst_user_class}->new( $id, { %{$self} } );
    $user->id($user->canonical_id);

    if( $self->{auth}{auto_create_user} and !$user->obj ) {
        $self->{auth}{user_class}->auto_create( $id, @rest ) and return $self->get_user( $id );
    }

    $user->store( $self );

    if( $self->{auth}{auto_update_user} && $user->obj ) {
        $user->obj->auto_update( $id, @rest );
    }

    return $user;
}

sub user_supports {
    # this can work as a class method
    shift->{auth}{catalyst_user_class}->supports( @_ );
}

1;

__END__

=pod

=head1 NAME

Catalyst::Plugin::Authentication::Store::DBIC::Backend - DBIx::Class
authentication storage backend.

=head1 DESCRIPTION

This class implements the storage backend for database authentication.

=head1 INTERNAL METHODS

=head2 new

=head2 from_session

=head2 get_user

=head2 user_supports

=head1 SEE ALSO

L<Catalyst::Plugin::Authentication::Store::DBIC>, L<Catalyst::Plugin::Authentication>,
L<Catalyst::Plugin::Authorization::Roles>

=head1 AUTHORS

David Kamholz, <dkamholz@cpan.org>

Andy Grundman

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
