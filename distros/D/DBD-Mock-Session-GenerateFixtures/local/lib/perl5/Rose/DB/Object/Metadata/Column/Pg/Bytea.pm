package Rose::DB::Object::Metadata::Column::Pg::Bytea;

use strict;

TRY: { local $@; eval { require DBD::Pg } } # ignore errors

use Rose::DB::Object::Metadata::Column;
our @ISA = qw(Rose::DB::Object::Metadata::Column);

our $VERSION = '0.784';

sub type { 'bytea' }

sub dbi_requires_bind_param 
{
  my($self, $db) = @_;
  return $db->driver eq 'pg' ? 1 : 0;
}

sub dbi_bind_param_attrs 
{
  my($self, $db) = @_;
  return $db->driver eq 'pg' ? { pg_type => DBD::Pg::PG_BYTEA() } : {};
}

1;

__END__

=head1 NAME

Rose::DB::Object::Metadata::Column::Pg::Bytea - PostgreSQL BYTEA column metadata.

=head1 SYNOPSIS

  use Rose::DB::Object::Metadata::Column::Pg::Bytea;

  $col = Rose::DB::Object::Metadata::Column::Pg::Bytea->new(...);
  $col->make_methods(...);
  ...

=head1 DESCRIPTION

Objects of this class store and manipulate metadata for BYTEA columns in a PostgreSQL database.  Column metadata objects store information about columns (data type, size, etc.) and are responsible for creating object methods that manipulate column values.  See the PostgreSQL documentation for more information on the BYTEA data type.

L<http://www.postgresql.org/docs/8.1/interactive/datatype-binary.html>

This class inherits from L<Rose::DB::Object::Metadata::Column>. Inherited methods that are not overridden will not be documented a second time here.  See the L<Rose::DB::Object::Metadata::Column> documentation for more information.

=head1 METHOD MAP

=over 4

=item C<get_set>

L<Rose::DB::Object::MakeMethods::Generic>, L<scalar|Rose::DB::Object::MakeMethods::Generic/scalar>, ...

=item C<get>

L<Rose::DB::Object::MakeMethods::Generic>, L<scalar|Rose::DB::Object::MakeMethods::Generic/scalar>, ...

=item C<get_set>

L<Rose::DB::Object::MakeMethods::Generic>, L<scalar|Rose::DB::Object::MakeMethods::Generic/scalar>, ...

=back

See the L<Rose::DB::Object::Metadata::Column|Rose::DB::Object::Metadata::Column/"MAKING METHODS"> documentation for an explanation of this method map.

=head1 OBJECT METHODS

=over 4

=item B<type>

Returns "bytea".

=back

=head1 AUTHOR

John C. Siracusa (siracusa@gmail.com)

=head1 LICENSE

Copyright (c) 2010 by John C. Siracusa.  All rights reserved.  This program is
free software; you can redistribute it and/or modify it under the same terms
as Perl itself.
