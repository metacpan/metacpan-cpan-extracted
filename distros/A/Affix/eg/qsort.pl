use v5.40;
use Affix qw[:all];

# Demonstrate callbacks with libc's qsort
#    void qsort(void *base, size_t nmemb, size_t size,
#               int (*compar)(const void *, const void *));
# Define the comparison callback: (int*, int*) -> int
my $comparator_type = Callback [ [ Pointer [Int], Pointer [Int] ] => Int ];
affix libc(), 'qsort', [ Pointer [Int], Size_t, Size_t, $comparator_type ] => Void;

# Perl subroutine acting as the C callback
my $compare_func = sub ( $a, $b ) {
    return $$a <=> $$b;    # Dereference the integer pointers
};

# Create a packed array of integers (Standard Perl integer packing)
my @numbers = ( 88, 56, 100, 2, 25 );
say "Unsorted: " . join( ', ', @numbers );

# Affix handles the ArrayRef -> Pointer[Int] marshalling automatically
qsort( \@numbers, scalar @numbers, sizeof(Int), $compare_func );
#
say "Sorted:   " . join( ', ', @numbers );
