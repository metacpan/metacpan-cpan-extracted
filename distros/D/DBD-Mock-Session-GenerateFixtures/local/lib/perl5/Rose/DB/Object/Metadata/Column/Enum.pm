package Rose::DB::Object::Metadata::Column::Enum;

use strict;

use Rose::DB::Object::Metadata::Column::Integer;
our @ISA = qw(Rose::DB::Object::Metadata::Column::Integer);

our $VERSION = '0.55';

foreach my $type (__PACKAGE__->available_method_types)
{
  __PACKAGE__->method_maker_type($type => 'enum');
}

sub type { 'enum' }

*values = \&Rose::DB::Object::Metadata::Column::Scalar::check_in;

sub init_with_dbi_column_info
{
  my($self, $col_info) = @_;

  $self->SUPER::init_with_dbi_column_info($col_info);

  if(ref $col_info->{'RDBO_ENUM_VALUES'})
  {
    $self->values($col_info->{'RDBO_ENUM_VALUES'});
  }

  return;
}

1;

__END__

=head1 NAME

Rose::DB::Object::Metadata::Column::Enum - Enumerated column metadata.

=head1 SYNOPSIS

  use Rose::DB::Object::Metadata::Column::Enum;

  $col = Rose::DB::Object::Metadata::Column::Enum->new(...);
  $col->make_methods(...);
  ...

=head1 DESCRIPTION

Objects of this class store and manipulate metadata for enum columns.  Column metadata objects store information about columns (data type, size, etc.) and are responsible for creating object methods that manipulate column values.  An enum column accepts a restricted set of string values which are usually stored as sequential integers in the database.

This class inherits from L<Rose::DB::Object::Metadata::Column::Scalar>. Inherited methods that are not overridden will not be documented a second time here.  See the L<Rose::DB::Object::Metadata::Column::Scalar> documentation for more information.

=head1 METHOD MAP

=over 4

=item C<get_set>

L<Rose::DB::Object::MakeMethods::Generic>, L<enum|Rose::DB::Object::MakeMethods::Generic/enum>, C<interface =E<gt> 'get_set', ...>

=item C<get>

L<Rose::DB::Object::MakeMethods::Generic>, L<enum|Rose::DB::Object::MakeMethods::Generic/enum>, C<interface =E<gt> 'get', ...>

=item C<get_set>

L<Rose::DB::Object::MakeMethods::Generic>, L<enum|Rose::DB::Object::MakeMethods::Generic/enum>, C<interface =E<gt> 'set', ...>

=back

See the L<Rose::DB::Object::Metadata::Column|Rose::DB::Object::Metadata::Column/"MAKING METHODS"> documentation for an explanation of this method map.

=head1 OBJECT METHODS

=over 4

=item B<type>

Returns "enum".

=item B<values [VALUES]>

Get or set a reference to an array of valid column values.  This attribute is required.

=back

=head1 AUTHOR

John C. Siracusa (siracusa@gmail.com)

=head1 LICENSE

Copyright (c) 2010 by John C. Siracusa.  All rights reserved.  This program is
free software; you can redistribute it and/or modify it under the same terms
as Perl itself.
