package Catalyst::Authentication::Store::Model::KiokuDB;
use Moose;

use Carp;

use Catalyst::Authentication::Store::Model::KiokuDB::UserWrapper;

use namespace::clean -except => 'meta';

sub BUILDARGS {
    my ($class, $conf, $app, $realm) = @_;

    return {
        app => $app,
        realm => $realm,
        %$conf,
    }
}

has realm => (
    is => "ro",
);

has model_name => (
    isa => "Str",
    is  => "ro",
    required => 1,
);

has user_prefix => (
    is      => 'ro',
    isa     => 'Str',
    default => 'user:',
);

sub get_model {
    my ( $self, $c ) = @_;

    $c->model($self->model_name);
}

sub wrap {
    my ( $self, $c, $user ) = @_;

    croak "No user object" unless ref $user;

    return Catalyst::Authentication::Store::Model::KiokuDB::UserWrapper->new(
        directory   => $self->get_model($c)->directory,
        user_object => $user,
    );
}

sub from_session {
    my ( $self, $c, $id ) = @_;

    my $user = $self->get_model($c)->lookup($id);

    $self->wrap($c, $user);
}

sub find_user {
    my ( $self, $userinfo, $c ) = @_;

    my $model = $self->get_model($c);

    my $user = $model->can("find_user")
        ? $model->find_user($userinfo)
        : $self->find_user_by_id($userinfo, $model);

    if ( $user ) {
        return $self->wrap($c, $user);
    } else {
        return;
    }
}

sub find_user_by_id {
    my ( $self, $userinfo, $model ) = @_;

    my $id = $userinfo->{id};

    $id = $userinfo->{username}
        unless defined $id;

    croak "No user ID specified"
        unless defined $id;

    # KiokuX::User convention... FIXME also support ->search?
    $model->lookup($self->user_prefix . $id);
}

__PACKAGE__->meta->make_immutable;

__PACKAGE__

__END__

=head1 NAME

=head1 SYNOPSIS

    __PACKAGE__->config(
        'Plugin::Authentication' => {
            realms => {
                default => {
                    credential => {
                        # see L<KiokuX::User>
                        class         => 'Password',
                        password_type => 'self_check'
                    },
                    store => {
                        class      => 'Model::KiokuDB',
                        model_name => "kiokudb", # whatever your model is actually named
                    }
                }
            }
        }
    );

=head1 DESCRIPTION

This module provides the glue to use L<KiokuX::User> objects for authentication
inside L<Catalyst> apps that use L<Catalyst::Model::KiokuDB>.

The user object is wrapped with
L<Catalyst::Authentication::Store::Model::KiokuDB::UserWrapper>.

=cut
