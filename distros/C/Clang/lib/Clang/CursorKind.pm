package Clang::CursorKind;
$Clang::CursorKind::VERSION = '0.09';
use strict;
use warnings;

=head1 NAME

Clang::CursorKind - Clang cursor kind class

=head1 VERSION

version 0.09

=head1 DESCRIPTION

A C<Clang::CursorKind> describes the kind of entity that a cursor refers to.

=head1 METHODS

=head2 spelling( )

Retrieve the name of the given cursor kind.

=head2 is_declaration( )

Determine whether the given cursor kind represents a declaration.

=head2 is_reference( )

Determine whether the given cursor kind represents a reference.

=head2 is_expression( )

Determine whether the given cursor kind represents an expression.

=head2 is_statement( )

Determine whether the given cursor kind represents a statement.

=head2 is_attribute( )

Determine whether the given cursor kind represents an attribute.

=head2 is_invalid( )

Determine whether the given cursor kind represents an invalid cursor.

=head2 is_tunit( )

Determine whether the given cursor kind represents a translation unit.

=head2 is_preprocessing( )

Determine whether the given cursor kind represents a preprocessing element.

=head2 is_unexposed( )

Determine whether the given cursor kind represents an unexposed piece of the
AST.

=head1 AUTHOR

Alessandro Ghedini <alexbio@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Alessandro Ghedini.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Clang::CursorKind
