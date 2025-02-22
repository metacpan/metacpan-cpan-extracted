package Rose::DB::Object::Metadata::Column::Float;

use strict;

use Rose::DB::Object::Metadata::Column::Numeric;
our @ISA = qw(Rose::DB::Object::Metadata::Column::Numeric);

our $VERSION = '0.788';

sub type { 'float' }

sub should_inline_value
{
  my($self, $db, $value) = @_;
  no warnings 'uninitialized';
  return (($db->validate_float_keyword($value) && $db->should_inline_float_keyword($value)) ||
          ($db->keyword_function_calls && $value =~ /^\w+\(.*\)$/)) ? 1 : 0;
}

1;

__END__

=head1 NAME

Rose::DB::Object::Metadata::Column::Float - Floating-point column metadata.

=head1 SYNOPSIS

  use Rose::DB::Object::Metadata::Column::Float;

  $col = Rose::DB::Object::Metadata::Column::Float->new(...);
  $col->make_methods(...);
  ...

=head1 DESCRIPTION

Objects of this class store and manipulate metadata for floating-point columns in a database.  Column metadata objects store information about columns (data type, size, etc.) and are responsible for creating object methods that manipulate column values.

This class inherits from L<Rose::DB::Object::Metadata::Column::Numeric>. Inherited methods that are not overridden will not be documented a second time here.  See the L<Rose::DB::Object::Metadata::Column::Numeric> documentation for more information.

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

=item B<type>

Returns "float".

=back

=head1 AUTHOR

John C. Siracusa (siracusa@gmail.com)

=head1 LICENSE

Copyright (c) 2010 by John C. Siracusa.  All rights reserved.  This program is
free software; you can redistribute it and/or modify it under the same terms
as Perl itself.
