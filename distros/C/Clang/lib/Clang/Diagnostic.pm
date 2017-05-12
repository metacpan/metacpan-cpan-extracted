package Clang::Diagnostic;
$Clang::Diagnostic::VERSION = '0.09';
use strict;
use warnings;

=head1 NAME

Clang::Diagnostic - Clang diagnostic class

=head1 VERSION

version 0.09

=head1 DESCRIPTION

A C<Clang::Diagnostic> represents a diagnostic reported by the compiler.

=head1 METHODS

=head2 format( $with_source )

Format the given C<Clang::Diagnostic> as string. If C<$with_source> is true, the
stringified source location of the diagnostic will be included.

=head2 location( )

Retrieve the location of the given diagnostic. This function returns three
values: a string containing the source file name, an integer containing the
line number and another integer containing the column number.

=head1 AUTHOR

Alessandro Ghedini <alexbio@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Alessandro Ghedini.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Clang::Diagnostic
