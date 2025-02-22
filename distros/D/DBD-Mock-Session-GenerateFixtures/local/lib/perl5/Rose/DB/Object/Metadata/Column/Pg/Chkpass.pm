package Rose::DB::Object::Metadata::Column::Pg::Chkpass;

use strict;

use Rose::Object::MakeMethods::Generic;
use Rose::DB::Object::MakeMethods::Pg;

use Rose::DB::Object::Metadata::Column;
our @ISA = qw(Rose::DB::Object::Metadata::Column);

our $VERSION = '0.03';

__PACKAGE__->add_common_method_maker_argument_names('encrypted_suffix', 'cmp_suffix');

Rose::Object::MakeMethods::Generic->make_methods
(
  { preserve_existing => 1 },
  scalar => [ __PACKAGE__->common_method_maker_argument_names ]
);

foreach my $type (__PACKAGE__->available_method_types)
{
  __PACKAGE__->method_maker_class($type => 'Rose::DB::Object::MakeMethods::Pg');
  __PACKAGE__->method_maker_type($type => 'chkpass');
}

sub type { 'chkpass' }

1;

__END__

=head1 NAME

Rose::DB::Object::Metadata::Column::Pg::Chkpass - PostgreSQL CHKPASS column metadata.

=head1 SYNOPSIS

  use Rose::DB::Object::Metadata::Column::Pg::Chkpass;

  $col = Rose::DB::Object::Metadata::Column::Pg::Chkpass->new(...);
  $col->make_methods(...);
  ...

=head1 DESCRIPTION

Objects of this class store and manipulate metadata for CHKPASS columns in a PostgreSQL database.  Column metadata objects store information about columns (data type, size, etc.) and are responsible for creating object methods that manipulate column values.  See the L<Rose::DB::Object::MakeMethods::Pg> for more information on PostgreSQL's CHKPASS data type.

This class inherits from L<Rose::DB::Object::Metadata::Column>. Inherited methods that are not overridden will not be documented a second time here.  See the L<Rose::DB::Object::Metadata::Column> documentation for more information.

=head1 METHOD MAP

=over 4

=item C<get_set>

L<Rose::DB::Object::MakeMethods::Pg>, L<chkpass|Rose::DB::Object::MakeMethods::Pg/chkpass>, ...

=item C<get>

L<Rose::DB::Object::MakeMethods::Pg>, L<chkpass|Rose::DB::Object::MakeMethods::Pg/chkpass>, ...

=item C<get_set>

L<Rose::DB::Object::MakeMethods::Pg>, L<chkpass|Rose::DB::Object::MakeMethods::Pg/chkpass>, ...

=back

See the L<Rose::DB::Object::Metadata::Column|Rose::DB::Object::Metadata::Column/"MAKING METHODS"> documentation for an explanation of this method map.

=head1 OBJECT METHODS

=over 4

=item B<cmp_suffix [STRING]>

Get or set the suffix used to form the name of the comparison method.   See the documentation for the C<chkpass> method type in L<Rose::DB::Object::MakeMethods::Pg> for more information.

=item B<encrypted_suffix [STRING]>

Get or set the suffix used to form the name of the accessor method for the encrypted version of the column value.   See the documentation for the C<chkpass> method type in L<Rose::DB::Object::MakeMethods::Pg> for more information.

=item B<type>

Returns "chkpass".

=back

=head1 AUTHOR

John C. Siracusa (siracusa@gmail.com)

=head1 LICENSE

Copyright (c) 2010 by John C. Siracusa.  All rights reserved.  This program is
free software; you can redistribute it and/or modify it under the same terms
as Perl itself.
