package CPAN::Index;

use 5.005;
use strict;
use DBI         ();
use DBD::SQLite ();
use base 'DBIx::Class::Schema';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}

__PACKAGE__->load_classes('Author', 'Package', 'Distribution');

1;

__END__

=pod

=head1 NAME

CPAN::Index - Robust and object-oriented access to the CPAN index

=head1 DESCRIPTION

There are many parts of the CPAN toolchain that might benefit from
convenient access to the CPAN index metadata.

But for legacy compatibility reasons, most of this metadata is provided
in the form of three venerable uniquely-formatted text files.

Generally, this means that if you want access to them, you need to pull
the files from the CPAN, write a parser, store the objects in memory,
maybe cache them with Storable, and write your own hash indexing
and object-walking functions.

However, with the CPAN still growing, and further accelerating,
it is becoming increasingly unfeasible to store the CPAN metadata
solely in memory structures.

A more robust, richer, and more convenient approach is required.

B<CPAN::Index> provides object-oriented access to the CPAN index,
using a collection of relatively common modules, and automates
entire process of fetching and accessing the index.

The index is stored in a L<DBD::SQLite> database file, with an object
model implemented around it using L<DBIx::Class>. To update the index,
the L<CPAN::Index::Loader> class implements the logic to flush and reset
the database, fetch the index files, parse them, and repopulate the
database.

=head1 TO DO

- Write the index file download code

- Verify CPAN::Index handles index unicode data properly

- A bunch of other things...

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CPAN-Index>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>cpan@ali.asE<gt>

=head1 SEE ALSO

L<CPAN::Index::Loader>, L<DBD::SQLite>, L<DBIx::Class>

=head1 COPYRIGHT

Copyright (c) 2006 Adam Kennedy. All rights reserved.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
