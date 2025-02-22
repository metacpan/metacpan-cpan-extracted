package Rose::DB::Object::Metadata::Column::Integer;

use strict;

use Rose::DB::Object::Metadata::Column::Scalar;
our @ISA = qw(Rose::DB::Object::Metadata::Column::Scalar);

our $VERSION = '0.788';

__PACKAGE__->add_common_method_maker_argument_names(qw(min max));
__PACKAGE__->delete_common_method_maker_argument_names(qw(length));

Rose::Object::MakeMethods::Generic->make_methods
(
  { preserve_existing => 1 },
  scalar => [ __PACKAGE__->common_method_maker_argument_names ]
);

foreach my $type (__PACKAGE__->available_method_types)
{
  __PACKAGE__->method_maker_type($type => 'integer');
}

sub type { 'integer' }

sub should_inline_value
{
  my($self, $db, $value) = @_;
  no warnings 'uninitialized';
  return (($db->validate_integer_keyword($value) && $db->should_inline_integer_keyword($value)) ||
          ($db->keyword_function_calls && $value =~ /^\w+\(.*\)$/)) ? 1 : 0;
}

sub perl_column_definition_attributes
{
  grep { $_ ne 'length' } shift->SUPER::perl_column_definition_attributes;
}

1;

__END__

=head1 NAME

Rose::DB::Object::Metadata::Column::Integer - Integer column metadata.

=head1 SYNOPSIS

  use Rose::DB::Object::Metadata::Column::Integer;

  $col = Rose::DB::Object::Metadata::Column::Integer->new(...);
  $col->make_methods(...);
  ...

=head1 DESCRIPTION

Objects of this class store and manipulate metadata for integer columns in a database.  Column metadata objects store information about columns (data type, size, etc.) and are responsible for creating object methods that manipulate column values.

This class inherits from L<Rose::DB::Object::Metadata::Column::Scalar>. Inherited methods that are not overridden will not be documented a second time here.  See the L<Rose::DB::Object::Metadata::Column::Scalar> documentation for more information.

=head1 METHOD MAP

=over 4

=item C<get_set>

L<Rose::DB::Object::MakeMethods::Generic>, L<integer|Rose::DB::Object::MakeMethods::Generic/integer>, C<interface =E<gt> 'get_set', ...>

=item C<get>

L<Rose::DB::Object::MakeMethods::Generic>, L<integer|Rose::DB::Object::MakeMethods::Generic/integer>, C<interface =E<gt> 'get', ...>

=item C<get_set>

L<Rose::DB::Object::MakeMethods::Generic>, L<integer|Rose::DB::Object::MakeMethods::Generic/integer>, C<interface =E<gt> 'set', ...>

=back

See the L<Rose::DB::Object::Metadata::Column|Rose::DB::Object::Metadata::Column/"MAKING METHODS"> documentation for an explanation of this method map.

=head1 OBJECT METHODS

=over 4

=item B<max [INT]>

Get or set the maximum value this column is allowed to have.

=item B<min [INT]>

Get or set the minimum value this column is allowed to have.

=item B<type>

Returns "integer".

=back

=head1 AUTHOR

John C. Siracusa (siracusa@gmail.com)

=head1 LICENSE

Copyright (c) 2010 by John C. Siracusa.  All rights reserved.  This program is
free software; you can redistribute it and/or modify it under the same terms
as Perl itself.
