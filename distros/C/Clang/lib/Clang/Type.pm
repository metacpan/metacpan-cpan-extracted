package Clang::Type;
$Clang::Type::VERSION = '0.09';
use strict;
use warnings;

=head1 NAME

Clang::Type - Clang type class

=head1 VERSION

version 0.09

=head1 DESCRIPTION

A C<Clang::Type> represents the type of an element in the AST.

=head1 METHODS

=head2 declaration( )

Retrieve the L<Clang::Cursor> that points to the declaration of the given type.

=head2 kind( )

Retrieve the L<Clang::TypeKind> of the given type.

=head2 is_const( )

Determine whether the given type has the "const" qualifier.

=head2 is_volatile( )

Determine whether the given type has the "volatile" qualifier.

=head2 is_restrict( )

Determine whether the given type has the "restrict" qualifier.

=head1 AUTHOR

Alessandro Ghedini <alexbio@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Alessandro Ghedini.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Clang::Type
