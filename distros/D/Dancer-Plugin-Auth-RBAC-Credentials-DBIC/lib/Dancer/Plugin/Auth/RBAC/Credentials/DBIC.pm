package Dancer::Plugin::Auth::RBAC::Credentials::DBIC;
BEGIN {
  $Dancer::Plugin::Auth::RBAC::Credentials::DBIC::VERSION = '0.003';
}
# ABSTRACT: Dancer::Plugin::Auth::RBAC authentication via DBIx::Class

use strict;
use warnings;

use parent 'Dancer::Plugin::Auth::RBAC::Credentials';
use Dancer::Plugin::DBIC 0.15;


sub authorize {
    my ($self, $options, $login, $password) = @_;

    if (defined($login) && length($login)) {

        unless (defined($password) && length($password)) {
            $self->errors('login and password are required');
            return 0;
        }
        my $moniker = $options->{user_moniker} ||= "User";
        my $login_field = $options->{login_field} ||= "login";
        my $password_field = $options->{password_field} ||= "password";
        my $password_type = $options->{password_type} ||= "clear";
        my $id_field = $options->{id_field} ||= "id";
        my $name_field = $options->{name_field} ||= "name";
        my $role_relation = exists($options->{role_relation}) ? $options->{role_relation} : "roles";
        my $role_name_field = $options->{role_name_field} ||= "name";
        my $user_rs = schema($options->{handle})->resultset($moniker);

        if (my $user = $user_rs->find({ $login_field => $login })) {
            if ($self->_check_password($options, $user, $password)) {
                return $self->credentials({
                    id => $user->$id_field,
                    name => $user->$name_field,
                    login => $user->$login_field,
                    roles => defined($role_relation) ? [ $user->$role_relation->get_column($role_name_field)->all ] : [],
                    error => [],
                });
            }
        }

        $self->errors('login and/or password is invalid');
        return 0;
    }
    else {
        my $user = $self->{credentials};
        if ($user->{id} || $user->{login} && !@{$user->{error}}) {
            return $user;
        }
        else {
            $self->errors('you are not authorized', 'your session may have ended');
            return 0;
        }
    }
}

sub _check_password {
    my ($self, $options, $user, $password) = @_;
    my $password_type = $options->{password_type};
    if ($password_type eq "self_check") {
        return $user->check_password($password);
    }
    else {
        my $password_field = $options->{password_field};
        my $stored_password = $user->$password_field;
        if ($password_type eq "clear") {
            return $password eq $stored_password;
        }
        else {
            die "Unsupported password type '$password_type'";
        }
    }
}


1;

__END__
=pod

=head1 NAME

Dancer::Plugin::Auth::RBAC::Credentials::DBIC - Dancer::Plugin::Auth::RBAC authentication via DBIx::Class

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    # in your app code
    my $auth = auth($login, $password);
    if ($auth) {
        # login successful
    }

=head1 DESCRIPTION

Dancer::Plugin::Auth::RBAC::Credentials::DBIC uses your L<DBIx::Class>
schema as the application's user management system.

=head1 METHODS

=head2 authorize

Validates a user against the defined L<DBIx::Class> schema using the
supplied arguments and configuration file options.

=head1 CONFIGURATION

Minimal example:

    plugins:
      DBIC:
        Auth:
          dsn: "dbi:SQLite:dbname=./foo.db"
      Auth::RBAC:
        credentials:
          class: DBIC

The following config options are avaialable:

=over

=item handle

The handle of the L<Dancer::Plugin::DBIC> schema to use.
Only needed if you have more than one schema defined.

=item user_moniker

The moniker for the result source which holds your users.
Default C<User>.

=item login_field

The name of the field that the login name is stored in.
Default C<login>.

=item password_field

The name of the field that the password is stored in.
Default C<password>.

=item password_type

This sets the password type.  In order for the password module to verify
the plaintext password passed in, it must be told what format the
password will be in when it is retreived from the user object. The
supported options are:

=over

=item clear

The password is stored in clear text and will be compared directly.
This is the default.

=item self_check

The password will be passed to the C<check_password()> method of the
user object.

=back

=item id_field

The name of the field that the user id is stored in.
Default C<id>.

=item name_field

The name of the field that the user's name is stored in.
Default C<name>.

=item role_relation

The name of the relationship to get the roles of a user.
Default C<roles>.  Set to C<undef> if you're not using roles.

=item role_name_field

The name of the field on the role object that the role name is stored
in.
Default C<name>.

=back

=head1 AUTHOR

Dagfinn Ilmari Mannsåker <ilmari@photobox.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Photobox Limited.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

