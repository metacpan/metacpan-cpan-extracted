package Dancer::Plugin::Auth::RBAC::Permissions::DBIC;
BEGIN {
    $Dancer::Plugin::Auth::RBAC::Permissions::DBIC::VERSION = '0.003';
}

use strict;
use warnings;

use parent 'Dancer::Plugin::Auth::RBAC::Permissions';
use Dancer::Plugin::DBIC 0.15;

sub subject_asa {
    my ($self, $options, @arguments) = @_;
    my $role = shift @arguments;
    return unless $role;
    my $user = $self->credentials;
    return unless $user->{id};
    my $settings = $class::settings;

    my $moniker = $options->{user_moniker} ||= "User";
    my $role_relation = exists($options->{role_relation}) ? $options->{role_relation} : "roles";
    my $role_name_field = $options->{role_name_field} ||= "name";
    my $user_rs = schema($options->{handle})->resultset($moniker);

    if ( $role ) {
        if (my $user = $user_rs->find($user->{id})) {
            if ($user->$role_relation->search({ $role_name_field => $role })->first) {
                return 1;
            }
        }
    }
    return;
}

sub subject_can {
    my ($self, $options, @arguments) = @_;
    my ($operation, $action) = @arguments;
    return unless $operation && $action;
    my $user = $self->credentials;
    return unless $user->{id};
    my $settings = $class::settings;

    my $moniker = $options->{user_moniker} ||= "User";
    my $role_relation = exists($options->{role_relation}) ? $options->{role_relation} : "roles";
    my $perm_relation = exists($options->{perm_relation}) ? $options->{perm_relation} : "permissions";
    my $ops_relation = exists($options->{ops_relation}) ? $options->{ops_relation} : "operations";
    my $role_name_field = $options->{role_name_field} ||= "name";
    my $perm_name_field = $options->{perm_name_field} ||= "name";
    my $ops_name_field = $options->{ops_name_field} ||= "name";
    my $user_rs = schema($options->{handle})->resultset($moniker);

    my @roles = $user_rs->find($user->{id})->$role_relation->all();
    foreach my $role ( @roles ) {
        if ( my $p = $role->$perm_relation->search({$perm_name_field => $operation})->first) {
            return 1 if $p->$ops_relation->search({$ops_name_field => $action})->first;
        }
    }
    return;
}

1;

__END__
=head1 NAME

Dancer::Plugin::Auth::RBAC::Permissions::DBIC - Auth::RBAC Permissions via DBIx::Class

=head1 SYNOPSIS

  if ( auth->asa('guest') ) {
    ...
  }
  if ( auth->can('manage_accounts', 'create') ) {
    ...
  }

=head1 DESCRIPTION

Uses your DBIx::Class schema to provide the authorisation part of the 
RBAC user management system.

Note that you do not use this module directly. Use 
Dancer::Plugin::Auth::RBAC and configure it to use the DBIC class in your 
Dancer configuration (see below).

See Dancer::Plugin::Auth::RBAC::Credentials::DBIC for authentication and 
role management via DBIC.

=head1 METHODS

There are no public methods directly from this module. Use asa and can 
from Dancer::Plugin::Auth::RBAC

=head1 CONFIGURATION

Minimal example:

    plugins:
      DBIC:
        Auth:
          dsn: "dbi:SQLite:dbname=./foo.db"
        Auth::RBAC:
          credentials:
            class: DBIC
          permissions:
            class: DBIC

The following config options are avaialable:

=over

=item handle

The handle of the L<Dancer::Plugin::DBIC> schema to use.
Only needed if you have more than one schema defined.

=item user_moniker

The moniker for the result source which holds your users.
Default C<User>.

=item role_relation

The name of the relationship to get the roles of a user.
Default C<roles>.

=item role_name_field

The name of the field on the role object that the role name is stored
in.
Default C<name>.

=item perm_relation

The name of the relationship to get the permissions for a role.
Default C<permissions>.

=item perm_name_field

The name of the field on the permissions object that the permission
name is stored in.
Default C<name>.

=item ops_relation

The name of the relationship to get the operations for a permission.
Default C<operations>.

=item ops_name_field

The name of the field on the operations object that the operation
name is stored in.
Default C<name>.

=back

=head2 DBIx::Class RELATIONSHIPS

The RBAC relationships are as follows:

user has_many roles has_many permissions has_many operations

=head1 SEE ALSO

Dancer::Plugin::DBIC
Dancer::Plugin::Auth::RBAC
Dancer::Plugin::Auth::RBAC::Credentials::DBIC
DBIx::Class

=head1 AUTHOR

Jason Clifford, E<lt>jason@ukfsn.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Jason Clifford

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

