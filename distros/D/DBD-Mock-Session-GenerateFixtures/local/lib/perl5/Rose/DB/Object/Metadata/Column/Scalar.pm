package Rose::DB::Object::Metadata::Column::Scalar;

use strict;

use Rose::Object::MakeMethods::Generic;

use Rose::DB::Object::Metadata::Column;
our @ISA = qw(Rose::DB::Object::Metadata::Column);

our $VERSION = '0.60';

use Rose::Class::MakeMethods::Generic
(
  inheritable_scalar => 'default_overflow',
);

__PACKAGE__->default_overflow('fatal');

__PACKAGE__->add_common_method_maker_argument_names
(
  qw(default length check_in with_init init_method overflow)
);

Rose::Object::MakeMethods::Generic->make_methods
(
  { preserve_existing => 1 },

  'scalar --get_set_init' =>
  [
    overflow => { check_in => [ qw(truncate warn fatal) ] },
  ],

  scalar => [ __PACKAGE__->common_method_maker_argument_names ]
);

sub init_with_dbi_column_info
{
  my($self, $col_info) = @_;

  $self->SUPER::init_with_dbi_column_info($col_info);

  $self->length($col_info->{'COLUMN_SIZE'});

  return;
}

sub init_overflow { __PACKAGE__->default_overflow }

1;

__END__

=head1 NAME

Rose::DB::Object::Metadata::Column::Scalar - Scalar column metadata.

=head1 SYNOPSIS

  use Rose::DB::Object::Metadata::Column::Scalar;

  $col = Rose::DB::Object::Metadata::Column::Scalar->new(...);
  $col->make_methods(...);
  ...

=head1 DESCRIPTION

Objects of this class store and manipulate metadata for scalar columns in a database.  Column metadata objects store information about columns (data type, size, etc.) and are responsible for creating object methods that manipulate column values.

This class inherits from L<Rose::DB::Object::Metadata::Column>. Inherited methods that are not overridden will not be documented a second time here.  See the L<Rose::DB::Object::Metadata::Column> documentation for more information.

=head1 METHOD MAP

=over 4

=item C<get_set>

L<Rose::DB::Object::MakeMethods::Generic>, L<scalar|Rose::DB::Object::MakeMethods::Generic/scalar>, C<interface =E<gt> 'get_set', ...>

=item C<get>

L<Rose::DB::Object::MakeMethods::Generic>, L<scalar|Rose::DB::Object::MakeMethods::Generic/scalar>, C<interface =E<gt> 'get', ...>

=item C<get_set>

L<Rose::DB::Object::MakeMethods::Generic>, L<scalar|Rose::DB::Object::MakeMethods::Generic/scalar>, C<interface =E<gt> 'set', ...>

=back

See the L<Rose::DB::Object::Metadata::Column|Rose::DB::Object::Metadata::Column/"MAKING METHODS"> documentation for an explanation of this method map.

=head1 OBJECT METHODS

=over 4

=item B<check_in [ARRAYREF]>

Get or set a reference to an array of valid column values.

=item B<default VALUE>

Get or set the default value for the column.

=item B<init_method [NAME]>

Get or set the name of the "init" method.  See the documentation for the C<scalar> method type in L<Rose::DB::Object::MakeMethods::Generic> for more information.

=item B<length [INT]>

Get or set the length of the column in characters.

=item B<overflow [BEHAVIOR]>

Get or set the setting that determines the behavior when the column value is greater than L<length|/length> characters.  Valid values for BEHAVIOR are:

=over 4

=item B<fatal>

Throw an exception.

=item B<truncate>

Truncate the column value to the correct L<length|/length>.

=item B<warn>

Print a warning message.

=back

The default value is "fatal".

=item B<type>

Returns "scalar".

=item B<with_init [BOOL]>

Get or set the flag that determines whether or not the method created by C<make_method()> will include an "init" method as well.  See the documentation for the L<scalar|Rose::DB::Object::MakeMethods::Generic/scalar> method type in L<Rose::DB::Object::MakeMethods::Generic> for more information.

=back

=head1 AUTHOR

John C. Siracusa (siracusa@gmail.com)

=head1 LICENSE

Copyright (c) 2010 by John C. Siracusa.  All rights reserved.  This program is
free software; you can redistribute it and/or modify it under the same terms
as Perl itself.
