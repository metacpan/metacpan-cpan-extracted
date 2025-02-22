package Rose::DB::Object::Metadata::Relationship::OneToOne;

use strict;

use Rose::DB::Object::Metadata::Relationship::ManyToOne;
our @ISA = qw(Rose::DB::Object::Metadata::Relationship::ManyToOne);

our $VERSION = '0.771';

sub type { 'one to one' }

sub is_singular { 1 }

sub requires_preexisting_parent_object
{
  my($self) = shift;

  my $meta   = $self->parent;
  my $f_meta = $self->class->meta;

  my $column_map = $self->column_map;
  my %pk = map { $_ => 1 } $meta->primary_key_column_names;


  foreach my $local_column (keys %$column_map)
  {
    if($pk{$local_column})
    {
      return $self->{'requires_preexisting_parent_object'} = 1;
    }
  }

  return $self->{'requires_preexisting_parent_object'} = 0;
}

1;

__END__

=head1 NAME

Rose::DB::Object::Metadata::Relationship::OneToOne - One to one table relationship metadata object.

=head1 SYNOPSIS

  use Rose::DB::Object::Metadata::Relationship::OneToOne;

  $rel = Rose::DB::Object::Metadata::Relationship::OneToOne->new(...);
  $rel->make_methods(...);
  ...

=head1 DESCRIPTION

Objects of this class store and manipulate metadata for relationships in which a single row from one table refers to a single row in another table.

This class inherits from L<Rose::DB::Object::Metadata::Relationship>. Inherited methods that are not overridden will not be documented a second time here.  See the L<Rose::DB::Object::Metadata::Relationship> documentation for more information.

=head1 METHOD MAP

=over 4

=item C<get_set>

L<Rose::DB::Object::MakeMethods::Generic>, L<object_by_key|Rose::DB::Object::MakeMethods::Generic/object_by_key>, ...

=item C<get_set_now>

L<Rose::DB::Object::MakeMethods::Generic>, L<object_by_key|Rose::DB::Object::MakeMethods::Generic/object_by_key>, C<interface =E<gt> 'get_set_now'>

=item C<get_set_on_save>

L<Rose::DB::Object::MakeMethods::Generic>, L<object_by_key|Rose::DB::Object::MakeMethods::Generic/object_by_key>, C<interface =E<gt> 'get_set_on_save'>

=item C<delete_now>

L<Rose::DB::Object::MakeMethods::Generic>, L<object_by_key|Rose::DB::Object::MakeMethods::Generic/object_by_key>, C<interface =E<gt> 'delete_now'>

=item C<delete_on_save>

L<Rose::DB::Object::MakeMethods::Generic>, L<object_by_key|Rose::DB::Object::MakeMethods::Generic/object_by_key>, C<interface =E<gt> 'delete_on_save'>

=back

See the L<Rose::DB::Object::Metadata::Relationship|Rose::DB::Object::Metadata::Relationship/"MAKING METHODS"> documentation for an explanation of this method map.

=head1 CLASS METHODS

=over 4

=item B<default_auto_method_types [TYPES]>

Get or set the default list of L<auto_method_types|Rose::DB::Object::Metadata::Relationship/auto_method_types>.  TYPES should be a list of relationship method types.  Returns the list of default relationship method types (in list context) or a reference to an array of the default relationship method types (in scalar context).  The default list contains "get_set_on_save" and "delete_on_save".

=back

=head1 OBJECT METHODS

=over 4

=item B<column_map [HASH | HASHREF]>

Get or set a reference to a hash that maps local column names to foreign column names.

=item B<build_method_name_for_type TYPE>

Return a method name for the relationship method type TYPE.  

For the method types "get_set", "get_set_now", and "get_set_on_save", the relationship's L<name|Rose::DB::Object::Metadata::Relationship/name> is returned.

For the method types "delete_now" and "delete_on_save", the relationship's  L<name|Rose::DB::Object::Metadata::Relationship/name> prefixed with "delete_" is returned.

Otherwise, undef is returned.

=item B<is_singular>

Returns true.

=item B<foreign_key [FK]>

Get or set the L<Rose::DB::Object::Metadata::ForeignKey> object to which this object delegates all responsibility.

One to one relationships encapsulate essentially the same information as foreign keys.  If a foreign key object is stored in this relationship object, then I<all compatible operations are passed through to the foreign key object.>  This includes making object method(s) and adding or modifying the local-to-foreign column map.  In other words, if a L<foreign_key|/foreign_key> is set, the relationship object simply acts as a proxy for the foreign key object.

=item B<manager_class [CLASS]>

Get or set the name of the L<Rose::DB::Object::Manager>-derived class used to fetch the object.

=item B<manager_method [METHOD]>

Get or set the name of the L<manager_class|/manager_class> class method to call when fetching the object.

=item B<manager_args [HASHREF]>

Get or set a reference to a hash of name/value arguments to pass to the L<manager_method|/manager_method> when fetching the object.  See the documentation for L<Rose::DB::Object::Manager>'s L<get_objects|Rose::DB::Object::Manager/get_objects> method for a full list of valid arguments for use with the C<manager_args> parameter.

B<Note:> when the name of a relationship that has C<manager_args> is used in a L<Rose::DB::Object::Manager> L<with_objects|Rose::DB::Object::Manager/with_objects> or L<require_objects|Rose::DB::Object::Manager/require_objects> parameter value, I<only> the L<sort_by|Rose::DB::Object::Manager/sort_by> argument will be copied from C<manager_args> and incorporated into the query.

=item B<map_column LOCAL [, FOREIGN]>

If passed a local column name LOCAL, return the corresponding column name in the foreign table.  If passed both a local column name LOCAL and a foreign column name FOREIGN, set the local/foreign mapping and return the foreign column name.

=item B<optional [BOOL]>

This method is the mirror image of the L<required|/required> method.   Passing a true value to this method is the same thing as setting L<required|/required> to false, and vice versa.  Similarly, the return value is the logical negation of L<required|/required>.

=item B<query_args [ARRAYREF]>

Get or set a reference to an array of query arguments to add to the L<query|Rose::DB::Object::Manager/query> passed to the L<manager_method|/manager_method> when fetching the object.

=item B<required [BOOL]>

Get or set the boolean value that determines what happens when the local columns in the L<column_map|/column_map> have L<defined|perlfunc/defined> values, but the object they relate to is not found.  If true, a fatal error will occur when the methods that fetch objects through this relationship are called.  If false, then the methods will simply return undef.

The default is false if one or more of the local columns L<allow null values|Rose::DB::Object::Metadata::Column/not_null> or if the local columns in the column map are the same as the L<primary key columns|Rose::DB::Object::Metadata/primary_key_columns>, true otherwise.

=item B<type>

Returns "one to one".

=back

=head1 AUTHOR

John C. Siracusa (siracusa@gmail.com)

=head1 LICENSE

Copyright (c) 2010 by John C. Siracusa.  All rights reserved.  This program is
free software; you can redistribute it and/or modify it under the same terms
as Perl itself.
