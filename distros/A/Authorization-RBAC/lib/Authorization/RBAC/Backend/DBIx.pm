package Authorization::RBAC::Backend::DBIx;
$Authorization::RBAC::Backend::DBIx::VERSION = '0.12';
use Moose::Role;
use Carp qw/croak/;

use FindBin '$Bin';
require UNIVERSAL::require;


has typeobjs   => (
                     is         => 'rw',
                     default => sub{ return shift->schema->resultset('Typeobj')->search; }
                    );

has permissions   => (
                     is         => 'rw',
                     default => sub{ return shift->schema->resultset('Permission')->search; }
                    );


sub get_operations{
  my ($self, $operations) = @_;

  my @ops;
  foreach my $op  ( @$operations ) {
      my $op_rs = $self->schema->resultset('Operation')->search({ name => $op})->single;
      $self->_log("'$op' operation was not found in the database !!!")
          if ! $op_rs;
      push( @ops, $op_rs ) if $op_rs;
  }
  return @ops;
}

sub get_permission{
  my ($self, $role, $op, $obj) = @_;

  my $typeobj    = ref($obj);
  $typeobj =~ s/.*:://;
  my $typeobj_rs = $self->schema->resultset('Typeobj')->search({ name => $typeobj})->single;
  if ( ! $typeobj_rs ) {
      croak "'$typeobj' is unknown in the TypeObj table !";
  }

  my $permission = $self->schema->resultset('Permission')->search({ role_id      => $role->id,
                                                                    typeobj_id   => $typeobj_rs->id,
                                                                    obj_id       => $obj->id,
                                                                    operation_id => $op->id
                                                                  })->single;

  my $parent_field = $self->config->{typeobj}->{$typeobj}->{parent_field} || 'parent';

  if ( $permission ) {
    return ($permission->value, $permission->inheritable);
  }
  # Search permission on parents
  elsif ( $obj->can( $parent_field) ) {

    if ( $obj->$parent_field ){

      my $typeobj_parent    = ref($obj->$parent_field);
      $typeobj_parent =~ s/.*:://;
      $self->_log("  [??] Search inherited permissions on parents ${typeobj_parent}_" . $obj->$parent_field->id . "...");
      my ( $result, $inheritable)  = $self->get_permission($role, $op, $obj->$parent_field);
      if ( $inheritable || ! $result  ) {
        return ($result, $inheritable);
      }
    }
  }
  # No permission and no parent =>
  else {
      $self->_log("  No permission found :(");
      return 0;
  }
}


=head1 NAME

Authorization::RBAC::Backend::DBIx - Backend 'DBIx' for Authorization::RBAC

=head1 VERSION

version 0.12

=head1 CONFIGURATION

         use Catalyst qw/
                          Authorization::Roles
                          Authorization::RBAC
                        /;

         # in your config
         Authorization::RBAC:
           debug: 0
           backend:
             name: DBIx
             model: Model::RBAC

=head2 REQUIRED SCHEMA

See t/lib/Schema/RBAC/Result/

User -> UserRole -> Role

Role -> Permission -> Object ( -> TypeObj )
                   -> Operation

=head1 PROVIDED METHODS

=head2 get_operations( $operations )

=head2 get_permission( $role, $op, $obj )

=head1 AUTHOR

Daniel Brosseau, C<< <dab at catapulse.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Daniel Brosseau.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;
