=head1 NAME

Array::Heap - treat perl arrays as binary heaps/priority queues

=head1 SYNOPSIS

 use Array::Heap;

=head1 DESCRIPTION

There are a multitude of heap and heap-like modules on CPAN, you might
want to search for /Heap/ and /Priority/ to find many. They implement more
or less fancy datastructures that might well be what you are looking for.

This module takes a different approach: It exports functions (i.e. no
object orientation) that are loosely modeled after the C++ STL's binary
heap functions. They all take an array as argument, just like perl's
built-in functions C<push>, C<pop> etc.

The implementation itself is in C for maximum speed.

=head1 FUNCTIONS

All of the following functions are being exported by default.

=over 4

=cut

package Array::Heap;

BEGIN {
   $VERSION = 3.22;

   require XSLoader;
   XSLoader::load ("Array::Heap", $VERSION);
}

use base Exporter;

@EXPORT = qw(
   make_heap   make_heap_lex   make_heap_cmp   make_heap_idx
   push_heap   push_heap_lex   push_heap_cmp   push_heap_idx
   pop_heap    pop_heap_lex    pop_heap_cmp    pop_heap_idx
   splice_heap splice_heap_lex splice_heap_cmp splice_heap_idx
   adjust_heap adjust_heap_lex adjust_heap_cmp adjust_heap_idx
);

=item make_heap @heap                                   (\@)

Reorders the elements in the array so they form a heap, with the lowest
value "on top" of the heap (corresponding to the first array element).

=item make_heap_idx @heap                               (\@)

Just like C<make_heap>, but updates the index (see INDEXED OPERATIONS).

=item make_heap_lex @heap                               (\@)

Just like C<make_heap>, but in string comparison order instead of numerical
comparison order.

=item make_heap_cmp { compare } @heap                   (&\@)

Just like C<make_heap>, but takes a custom comparison function.

=item push_heap @heap, $element, ...                    (\@@)

Adds the given element(s) to the heap.

=item push_heap_idx @heap, $element, ...                (\@@)

Just like C<push_heap>,  but updates the index (see INDEXED OPERATIONS).

=item push_heap_lex @heap, $element, ...                (\@@)

Just like C<push_heap>, but in string comparison order instead of numerical
comparison order.

=item push_heap_cmp { compare } @heap, $element, ...    (&\@@)

Just like C<push_heap>, but takes a custom comparison function.

=item pop_heap @heap                                    (\@)

Removes the topmost (lowest) heap element and repairs the heap.

=item pop_heap_idx @heap                                (\@)

Just like C<pop_heap>, but updates the index (see INDEXED OPERATIONS).

=item pop_heap_lex @heap                                (\@)

Just like C<pop_heap>, but in string comparison order instead of numerical
comparison order.

=item pop_heap_cmp { compare } @heap                    (&\@)

Just like C<pop_heap>, but takes a custom comparison function.

=item splice_heap @heap, $index                         (\@$)

Similar to C<pop_heap>, but removes and returns the element at index
C<$index>.

=item splice_heap_idx @heap, $index                     (\@$)

Just like C<splice_heap>, but updates the index (see INDEXED OPERATIONS).

=item splice_heap_lex @heap, $index                     (\@$)

Just like C<splice_heap>, but in string comparison order instead of
numerical comparison order.

=item splice_heap_cmp { compare } @heap, $index         (&\@$)

Just like C<splice_heap>, but takes a custom comparison function.

=item adjust_heap @heap, $index                         (\@$)

Assuming you have only changed the element at index C<$index>, repair the
heap again. Can be used to remove elements, replace elements, adjust the
priority of elements and more.

=item adjust_heap_idx @heap, $index                     (\@$)

Just like C<adjust_heap>, but updates the index (see INDEXED OPERATIONS).

=item adjust_heap_lex @heap, $index                     (\@$)

Just like C<adjust_heap>, but in string comparison order instead of
numerical comparison order.

=item adjust_heap_cmp { compare } @heap, $index         (&\@$)

Just like C<adjust_heap>, but takes a custom comparison function.

=cut

1;

=back

=head2 COMPARISON FUNCTIONS

All the functions come in two flavours: one that uses the built-in
comparison function and one that uses a custom comparison function.

The built-in comparison function can either compare scalar numerical
values (string values for *_lex functions), or array refs. If the elements
to compare are array refs, the first element of the array is used for
comparison, i.e.

  1, 4, 6

will be sorted according to their numerical value,

  [1 => $obj1], [2 => $obj2], [3 => $obj3]

will sort according to the first element of the arrays, i.e. C<1,2,3>.

The custom comparison functions work similar to how C<sort> works: C<$a>
and C<$b> are set to the elements to be compared, and the result should be
greater than zero then $a is greater than $b, C<0> otherwise. This means
that you can use the same function as for sorting the array, but you could
also use a simpler function that just does C<< $a > $b >>.

The first example above corresponds to this comparison "function":

  { $a <=> $b }

And the second example corresponds to this:

  { $a->[0] <=> $b->[0] }

Unlike C<sort>, the default sort is numerical and it is not possible to
use normal subroutines.

=head2 INDEXED OPERATIONS

The functions whose names end in C<_idx> also "update the index". That
means that all elements must be array refs, with the first element being
the heap value, and the second value being the array index:

  [$value, $index, ...]

This allows you to quickly locate an element in the array when all you
have is the array reference.

=head1 BUGS

=over 4

=item * Numerical comparison is always done using floatingpoint, which
usually has less precision than a 64 bit integer that perl might use
for integers internally, resulting in precision loss on the built-in
comparison.

=item * This module does not work with tied or magical arrays or array
elements, and, in fact, will even crash when you use those.

=item * This module can leak memory (or worse) when your comparison
function exits unexpectedly (e.g. C<last>) or throws an exception, so do
not do that.

=back

=head1 SEE ALSO

This module has a rather low-level interface. If it seems daunting, you
should have a look at L<Array::Heap::ModifiablePriorityQueue>, which is
based on this module but provides more and higher-level operations with an
object-oriented API which makes it harder to make mistakes.

A slightly less flexible (only numeric weights), but also
slightly faster variant of that module can be found as
L<Array::Heap::PriorityQueue::Numeric> on CPAN.

=head1 AUTHOR AND CONTACT INFORMATION

 Marc Lehmann <schmorp@schmorp.de>
 http://software.schmorp.de/pkg/Array-Heap

=cut

