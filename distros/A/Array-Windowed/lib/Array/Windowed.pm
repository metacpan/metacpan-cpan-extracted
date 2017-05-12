package Array::Windowed;
use base qw(Exporter);

use strict;
use warnings;

#use Smart::Comments;
use List::Util qw(min max);

our @EXPORT_OK;

our $VERSION = "1.00";

=head1 NAME

Array::Windowed - return a windowed slice of the array

=head1 SYNOPSIS

   use Array::Windowed qw(windowed_array);

   # from an array
   my $new_array = array_window @old_array, $start_index, $count);

   # from an arrayref
   my $new_array2 = &array_window($array_ref, $start_index, $count);

=head1 DESCRIPTION

Simple module to return a slice of the passed array as specified by a start
position and a number of elements.  Unlike the built in slicing functions this
does not populate the returned array with C<undef>s for out of bounds
operations, but simply returns a smaller array.

=head1 FUNCTION

Exported on demand (or you can call it fully qualified)

=over

=item array_windowed @old_array, $start_index, $count

Returns an array reference containing up to C<$count> elements from the
C<@old_array> starting at C<$start_index>.

Unlike a traditional array slice elements outside the bounds of the array
are simply dropped.  Negative indexes are treated as normal indexes that
occur before the 0th index (rather than indexes counting backwards from
the start of the array.)

This is probably best shown with a series of examples:


	my @array = ['a'..'z'];

	# ["a".."z"]
	array_windowed(@array, 0, 26);

	# ["a","b","c","d","e"]
	array_windowed(@array, 0, 5);

	# ["b","c","d","e","f"]
	array_windowed(@array, 1, 5);

	# []
	array_windowed(@array, 26, 5);

	# []
	array_windowed(@array, -50, 5);

	# ["x","y","z"]
	array_windowed(@array, 23, 5);

	# ["a","b","c"]
	array_windowed(@array, -2, 5); 

	# ["a".."z"]
	&array_windowed(\@array, 0, 26);


=cut

sub array_windowed(\@$$) {
	my $array_ref = shift;
	my $start     = shift;
	my $count     = shift;

	my $first_index = max(0, $start);
	my $last_index  = min(@{ $array_ref } - 1, $start + $count - 1);

	# smart comment for debugging, uncomment use Smart::Comments above
	### $start
	### $count
	### $first_index
	### $last_index

	return [] if $last_index < 0;
	return [] if $first_index > $last_index;
	return [@{$array_ref}[$first_index..$last_index]];
}
push @EXPORT_OK, "array_windowed";

=back

=head1 RATIONALLE

Why this module?

=over

=item Why not simple array slices with @foo[ ... ]

Because the edge cases of indexes outside the bounds of the array don't do the
same thing (they return lots of C<undef>s mainly)

=item Why not splice?

It's destructive on the original array.

=item Why not Array::Window

Because it tries too hard to DTRT, which isn't the RT for us.  For example,
if you have a count bigger than the entire array then it always returns the
entire array irregardless of the start position.

This doesn't mean it's not the module for you, however.

=item Why not Data::Page

This concept of windowing we're using doesn't use pages, but rather
a start position and a count.

This doesn't mean it's not the module for you, however.

=back

=head1 AUTHOR

Written by Mark Fowler <mark@twoshortplanks.com>

=head1 COPYRIGHT

Copyright Mark Fowler 2012.  All Rights Reserved.

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 BUGS

This module does no sanity checking on the values that are passed into
it (i.e. it does not check that C<$start> or C<$count> are integer numbers,
nor does it check that the first argument is an array reference if you disable
prototyping.)

Bugs should be reported via this distribution's
CPAN RT queue.  This can be found at
L<https://rt.cpan.org/Dist/Display.html?Array-Windowed>

You can also address issues by forking this distribution
on github and sending pull requests.  It can be found at
L<http://github.com/2shortplanks/Array-Windowed>

=head1 SEE ALSO

L<Array::Window>, L<Data::Page>

=cut

1;

