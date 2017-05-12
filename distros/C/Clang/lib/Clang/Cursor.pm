package Clang::Cursor;
$Clang::Cursor::VERSION = '0.09';
use strict;
use warnings;

=head1 NAME

Clang::Cursor - Clang cursor class

=head1 VERSION

version 0.09

=head1 DESCRIPTION

A C<Clang::Cursor> represents an element in the abstract syntax tree of a
translation unit.

=head1 METHODS

=head2 kind( )

Retrieve the L<Clang::CursorKind> of the given cursor.

=head2 type( )

Retrieve the L<Clang::Type> of the entity referenced by the given cursor.

=head2 spelling( )

Retrieve the name for the entity referenced by the given cursor.

=head2 num_arguments( )

Retrieve the number of arguments referenced by the given cursor.

=head2 displayname( )

Return the display name for the entity referenced by the given cursor.

=head2 children( )

Retrieve a list of the children of the given cursor. The children are
C<Clang::Cursor> objects too.

=head2 is_pure_virtual( )

Determine whether the given cursor kind represents a pure virtual method.

=head2 is_virtual( )

Determine whether the given cursor kind represents a virtual method.

=head2 location( )

Retrieve the location of the given cursor. This function returns five values: a
string containing the source file name, an integer containing the initial line
number, an integer containing the initial column number, an integer containing
the final line number, and another integer containing the final column number.

=head2 access_specifier( )

Retrieve the access of the given cursor. This can return the following values:
C<invalid>, C<public>, C<protected> or C<private>. Note that this only works
for C++ code, it will return C<invalid> for C functions.

=head1 AUTHOR

Alessandro Ghedini <alexbio@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Alessandro Ghedini.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Clang::Cursor
