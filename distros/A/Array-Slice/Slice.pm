# $Id: Slice.pm,v 1.11 2007/04/16 07:33:29 dk Exp $
package Array::Slice;

use strict;
use warnings;
use Want qw(howmany);

our $VERSION = '0.03';
use base qw(DynaLoader Exporter);

our @EXPORT_OK   = qw(reset slice);
our %EXPORT_TAGS = ( all => \@EXPORT_OK);

bootstrap Array::Slice $VERSION;

sub slice(\@;$) { array_slice( $_[0], $#_ ? $_[1] : howmany) }

1;

=pod

=head1 NAME

Array::Slice - context-dependent array iterator

=head1 SYNOPSIS

    use Array::Slice qw(slice);

Iterate over an array assigning several items per cycle. Three:

    while ( my ( $x, $y, $z) = slice @arr) { ... }

or two:

    while ( my ( undef, $second) = slice @arr) { ... }

or even forty-two:

    while ( @a = slice @arr, 42) { ... }

=head1 DESCRIPTION

I've always wanted the power of C<foreach(@arr)> to be applied to arrays
working with more than one item at a time. Perl6 does it, Perl5 with source
filtering can do it, close, but no cigar. This module is an small step towards
the idea, an attempt to produce a way of slicing a single array with least
obtrusive syntax I can think of. 

The module works by attaching an integer counter to each scalar using perl
magic API, advancing the counter on each slice.

=over

=item slice @array, [ $howmany ]

Iterates over an array, returning C<$howmany> items perl call. If called without C<$howmany>,
deduces the number depending on the calling context.

=item reset @array, [ $whereto ]

Resets the array iterator to C<$whereto> or 0. C<$whereto> can be negavtive, as in
native array indexing.

=back

=head1 BUGS

Array items are copied, not aliased as in C<for>/C<foreach>.

Doesn't work with lists. This is one big TODO.

=head1 SEE ALSO

L<Array::Each::Override>, L<Array::Each>, L<Want>, L<List::MoreUtils>,
Synopsis 04(The 'for' statement).

=head1 THANKS

Aaron Crane for implementation of L<Array::Each::Override>, which code was used as base
for this module.

=head1 AUTHOR

Dmitry Karasik, E<lt>dmitry@karasik.eu.orgE<gt>.

=cut
