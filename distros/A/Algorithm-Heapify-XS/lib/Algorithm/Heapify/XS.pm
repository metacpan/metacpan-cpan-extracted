package Algorithm::Heapify::XS;

use 5.018004;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# This allows declaration:
#   use Algorithm::Heapify::XS ':all';

our %EXPORT_TAGS = (
    'all' => [
        'heap_parent_idx',
        'heap_left_child_idx',
        'heap_right_child_idx',
        map { ("min_$_", "max_$_","minstr_$_","maxstr_$_") }
            (
                'heapify',
                'heap_shift',
                'heap_push',
                'heap_adjust_top',
                'heap_adjust_item',
            )
    ]
);
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

foreach my $prefix (qw(max min maxstr minstr)) {
    $EXPORT_TAGS{$prefix}= [ grep { /^${prefix}_/ } @EXPORT_OK ];
}
$EXPORT_TAGS{idx}= [ grep { /_idx\z/ } @EXPORT_OK ];

our @EXPORT = qw();

our $VERSION = '0.04';

require XSLoader;
XSLoader::load('Algorithm::Heapify::XS', $VERSION);

sub heap_parent_idx($) {
    die "index must be non-negative" if $_[0] < 0;
    return $_[0] ? int(($_[0] - 1) / 2) : undef;
}

sub heap_left_child_idx($) {
    die "index must be non-negative" if $_[0] < 0;
    return 2*$_[0]+1;
}

sub heap_right_child_idx($) {
    die "index must be non-negative" if $_[0] < 0;
    return 2*$_[0]+2;
}


1;
__END__

=head1 NAME

Algorithm::Heapify::XS - Perl extension for supplying simple heap primitives for arrays.

=head1 SYNOPSIS

  use Algorithm::Heapify::XS qw(max_heapify max_heap_shift);
  my @array= (1..10);
  max_heapify(@array);
  while (defined(my $top= max_heap_shift(@array))) {
    print $top;
  }


=head1 DESCRIPTION

A heap is an array based data structure where the array is treated as a balanced tree
of items where each item obeys a given inequality constraint with its parent and children,
but not with its siblings. This allows it to be put into "nearly" sorted order more
efficiently than an actual sort would.

This data structure has a number of nice properties:

a) the tree does not require "child" pointers, but instead infers parent/child
relationships from their position in the array. The parent of a node i is defined to
reside in position int((i-1)/2), and the left and right children of a node i reside in
position (i*2+1) and (i*2+2) respectively.

b) "heapifying" an array is O(N) as compared to N * log2(N) for a typical sort.

c) Accessing the top item is O(1), and removing it from the array is O(log(N)).

d) Inserting a new item into the heap is O(log(N))

This means that for applications that need find only the top K of an array can do it faster
than sorting the array, and there is no need for wrapper objects to represent the tree.

=head2 INTERFACE

All operations are in-place on the array passed as an argument, and all require that the
appropriate "heapify" (either max_heapify or min_heapify) operation has been called on the
array first. Typically they return the "top" of the heap after the operation has been performed,
with the exception of the "shift" operation which returns the "top" of the heap before
removing it.

There are four variants of all subs provided. The "max_" and "min_" variants, and the
"maxstr_" and "minstr_" which provide descending and ascending and numeric and string
ordering respectively.  If you wish more precise control over the ordering of items
in the heap, such as objects, then C<use overload> to provide the required semantics by
overloading the appropriate inequality operators, typically just one of C<< <=> >> or C<cmp>
operators need be overloaded.

=head2 EXPORT

None by default. All exports must be requested, or you can use ":all" to import then all,
you can also import groups by prefix, eg ":max", ":min", ":maxstr", ":minstr" and ":idx"
to export

=head2 SUBS

=over 4

=item $max= max_heapify(@array)

=item $min= min_heapify(@array)

=item $maxstr= maxstr_heapify(@array)

=item $minstr= minstr_heapify(@array)

These subs "heapify" the array and return its "top" (min/max) value. Prior use of the
appropriate one of these subs is required to use all the other subs offered by this package.

=item $max= max_heap_shift(@array)

=item $min= min_heap_shift(@array)

=item $maxstr= maxstr_heap_shift(@array)

=item $minstr= minstr_heap_shift(@array)

Return and remove the "top" (min/max) value from a heapified array while maintain the arrays
heap-order.

=item $max= max_heap_push(@array)

=item $min= min_heap_push(@array)

=item $maxstr= maxstr_heap_push(@array)

=item $minstr= minstr_heap_push(@array)

Insert an item into a heapified array while maintaining the arrays heap-order, and return the
resulting "top" (min/max) value.

=item $max= max_heap_adjust_top(@array)

=item $min= min_heap_adjust_top(@array)

=item $maxstr= maxstr_heap_adjust_top(@array)

=item $minstr= minstr_heap_adjust_top(@array)

If the weight of the top item in a heapified array ($array[0]) has changed, this function will
adjust its position in the tree, and return the resulting new "top" (min/max) value.

=item $max= max_heap_adjust_item(@array,$idx)

=item $min= min_heap_adjust_item(@array,$idx)

=item $maxstr= maxstr_heap_adjust_item(@array,$idx)

=item $minstr= minstr_heap_adjust_item(@array,$idx)

If the weight of a specific item in a heapified array has changed, this function will
adjust its position in the tree, and return the resulting new "top" (min/max) value.
If $idx is outside the array does nothing.

=item $idx= heap_parent_idx($idx)

Returns the defined location for the node residing at index $idx in a heap, or undef if the $idx is 0.

=item $idx= heap_left_child_idx($idx)

=item $idx= heap_right_child_idx($idx)

Returns the defined location for the children of a node residing at index $idx in a heap.

=back

=head1 VERSION

This is version 0.04

=head1 INSTALLATION

To install this module type the following:

   perl Makefile.PL
   make
   make test
   make install

=head1 DEPENDENCIES

This module is implemented in XS, and requires a working C compiler and Perl build tools environment to build.

=head1 SEE ALSO

CPAN - There are other heap packages with different interfaces if you don't like this one.

=head1 AUTHOR

Yves Orton, E<lt>demerph@(that google thingee)E<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2018 by Yves Orton

This software is released under the "MIT License".

See the file B<LICENSE.txt> for more specifics.

=cut
