package Catalyst::Plugin::Authentication::Store::RDBO;
$VERSION = 0.002;

use strict;
use warnings;

use Catalyst::Plugin::Authentication::Store::RDBO::Backend;


sub setup {
    my $c = shift;

    # default values
    my %default = (user_field          => 'username',
                   password_field      => 'password',
                   password_type       => 'clear',
                   catalyst_user_class => 'Catalyst::Plugin::Authentication::Store::RDBO::User',
                  );
    while (my ($key, $value) = each %default) {
        $c->config->{authentication}{rdbo}{$key} ||= $value;
    }

    # set default store
    $c->default_auth_store(
        Catalyst::Plugin::Authentication::Store::RDBO::Backend->new(
            {auth  => $c->config->{authentication}{rdbo},
             authz => $c->config->{authorization}{rdbo},
            },
        ),
    );

    $c->NEXT::setup(@_);
}

sub setup_finished {
    my $c = shift;

    return $c->NEXT::setup_finished unless @_;

    my $backend = $c->default_auth_store;

    # complete user_class
    if (my $user_class = $backend->{auth}{user_class}) {
        my $model = $c->model($user_class);
        $backend->{auth}{user_class} = $model if $model;
    }
    else {
        Catalyst::Exception->throw(message => "You must provide a user_class");
    }

    # complete manager_class
    if (my $manager_class = $backend->{auth}{manager_class}) {
        my $manager = $c->model($manager_class);
        $backend->{auth}{manager_class} = $manager if $manager;
    }

    $c->NEXT::setup_finished(@_);
}

sub user_object {
    my $c = shift;

    return $c->user_exists ? $c->user->obj : undef;
}


1;

__END__


=head1 NAME

Catalyst::Plugin::Authentication::Store::RDBO - Authentication and
authorization against a Rose::DB::Object model.


=head1 VERSION

This document describes Catalyst::Plugin::Authentication::Store::RDBO
version 0.002.


=head1 SYNOPSIS

    use Catalyst;

    __PACKAGE__->setup(
        qw(
           Authentication
           Authentication::Store::DBIC
           Authentication::Credential::Password
           Authorization::Roles
          )
    );

    # Authentication
    __PACKAGE__->config->{authentication}{rdbo} = {
        user_class         => 'User',     # or 'MyApp::Model::User'
        user_field         => 'username',
        password_field     => 'password',
        password_type      => 'hashed',   # or 'clear'
        password_hash_type => 'SHA-1',
    };

    # Authorization
    __PACKAGE__->config->{authorization}{rdbo} = {
        role_rel   => 'roles',  # name of the many-to-many relationship
        role_field => 'name',
    };


=head1 DESCRIPTION

This plugin uses a L<Rose::DB::Object> object to authenticate an user.
It is based on L<Catalyst::Plugin::Authentication::Store::DBIC>. Please
read there for a much better description.


=head1 DIFFERENCES

Currently only a single field for the C<user_field> parameter is
supported. The DBIC plugin supports also an array reference. This can be
added in a future version.

The default for C<user_field> is C<username> instead of C<user>.

The configuration for authorization is much simpler, only two parameters
are needed. C<role_rel> specifies the name of the many-to-many
relationship which connects user and role names. C<role_field> is the
column accessor for the role name. (For
L<Catalyst::Plugin::Authorization::Roles> roles are just strings.)


=head1 AUTHOR

Uwe Voelker, <uwe.voelker@gmx.de>


=head1 COPYRIGHT

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See C<perldoc perlartistic>.
