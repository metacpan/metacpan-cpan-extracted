use 5.008008;
use strict;
use warnings;

package Arrays::Same;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.002';

require XSLoader;
'Arrays::Same'->XSLoader::load($VERSION);

require Exporter::Shiny;
'Exporter::Shiny'->import(qw( arrays_same_i arrays_same_s ));

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Arrays::Same - Test if two arrays are identical

=head1 SYNOPSIS

	use Arrays::Same -all;
	
	if (arrays_same_i(\@a, \@b)) {
		...;
	}

=head1 DESCRIPTION

This module exports two XS functions which test whether a pair of arrays are
identical. To be considered identical, the arrays must be of equal length, and
contain the same elements in the same order:

The C<arrays_same_i> function compares the elements as integers.

The C<arrays_same_s> function compares the elements as strings, and is
case-sensitive.

Both functions make the assumption that the arrays are simple lists of
non-reference scalars. They do not support overloading, etc, but dualvars
should work.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Arrays-Same>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2019 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

