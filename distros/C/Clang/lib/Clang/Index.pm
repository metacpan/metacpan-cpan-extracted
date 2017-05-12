package Clang::Index;
$Clang::Index::VERSION = '0.09';
use strict;
use warnings;

=head1 NAME

Clang::Index - Clang index class

=head1 VERSION

version 0.09

=head1 DESCRIPTION

A C<Clang::Index> represents a set of translation units that would typically
be linked together into an executable or library.

=head1 METHODS

=head2 new( $exclude_declarations )

Create a new C<Clang::Index> object.

=head2 parse( $filename )

Parse the file C<$filename> and retrieve the corresponding L<Clang::TUnit>.

=head1 AUTHOR

Alessandro Ghedini <alexbio@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Alessandro Ghedini.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Clang::Index
