#!/home/chrisarg/perl5/perlbrew/perls/current/bin/perl
package Bit::Set;
$Bit::Set::VERSION = '0.12';
use strict;
use warnings;

use XSLoader ();
XSLoader::load('Bit::Set');

use Exporter 'import';

our @EXPORT = qw(Bit_new Bit_free);
our @EXPORT_OK = qw(
  Bit_load Bit_extract
  Bit_buffer_size Bit_length Bit_count
  Bit_aset Bit_bset Bit_aclear Bit_bclear Bit_clear Bit_get Bit_not Bit_put Bit_set
  Bit_eq Bit_leq Bit_lt
  Bit_diff Bit_inter Bit_minus Bit_union
  Bit_diff_count Bit_inter_count Bit_minus_count Bit_union_count
  Bit_IVSIZE
);
our %EXPORT_TAGS = ( all => [ @EXPORT, @EXPORT_OK ] );

use constant RETURN_PERL_ARRAY => 0;
use constant RETURN_RAW_BUFFER => 1;
1;

__END__

=head1 NAME

Bit::Set - Perl procedural interface to the 'bit' C library

=head1 VERSION

version 0.12

=head1 SYNOPSIS

  use Bit::Set qw(:all);

  # Create a new bitset
  my $set = Bit_new(1024);

  # Set some bits
  Bit_bset($set, 0);
  Bit_bset($set, 42);


  # Get population count
  my $count = Bit_count($set);

  # Free the bitset
  Bit_free(\$set);

=head1 DESCRIPTION

This module provides a procedural Perl interface to the C library L<Bit|https://github.com/chrisarg/Bit>,
for creating and manipulating bitsets. It uses C<Alien::Bit> to locate and link to the C library and up to version 0.10 of the package it relied on  C<FFI::Platypus> to bind to the C functions. B<As of version 0.11 the procedural interface is implemented using XS>, and does not
invoke the library via FFI.

The API is a direct mapping of the C functions. For detailed semantics of each
function, please refer to L<Bit|https://github.com/chrisarg/Bit>.

Runtime checks on arguments are performed if the C<DEBUG> environment variable
is set to a true value when installing the code.

Only the constructor and destructor are exported by default. You can import all functions using the C<:all> tag, or import individual functions as needed.

=head2 Note on the Procedural interface

The initial B<procedural> API in the module was created during a "vibecoding" experiment in Github Copilot running through the VS Code editor. The section C<VIBECODING A FFI API THAT DIRECTLY MAPS THE C INTERFACE OF BIT> of the documentation (versions 0.11 and earlier) discusses the prompts used to generate the FFI bindings, and the manual edits of the generated code. 

During benchmarking at version 0.10 of the package,  it became obvious that the code was slower than what it should have been,  and Joe Schaefer (PAUSEID L<JOESUF|https://metacpan.org/author/JOESUF>) kindly contributed a direct XS interface to improve performance of the OO interface relative to the FFI version. I used Joe's XS code as a blueprint to generate the XS bindings for the procedural interface; the benchmarking github repository
L<benchmarking-bits|https://github.com/chrisarg/benchmarking-bits> executes a full benchmark of the performance enhancement of the XS version relative to the FFI version. As this is my first XS implementation, I took wild liberties in the implementation, and I welcome any suggestions for improvement from XS experts. In particular, I most likely should have used more of the builtin typemaps instead of writing my own typemaps or using C macros for type conversion.

=head2 Note on the Object Oriented interface

I had hesitated to release an B<Object Oriented> API for the Bit library largely because of performance concerns. The OO interface released with v0.10 was layered on top of the procedural API, and thus incur considerable overhead compared to direct calls to the procedural API. See L<Bit::Set::OO|https://metacpan.org/pod/Bit::Set::OO> for the OO interface. The initial OO interface was created manually without AI coding assistance. 

B<As of v0.11, both the OO and the procedural interfaces bind to the underlying C code using manually generated XS (contributed by JOESUF), and not through the "vibecoded" FFI binding.> We chose NOT to retain the "vibecoding" sections in the documentation as they are no longer relevant to the current implementation.

The OO interface's performance can be increased by 5%-15% by using JOESUF's technique of sealing the object to avoid the overhead of dynamic method lookup, i.e. the methods are resolved at compile time. 


=head1 Functions in the procedural interface

The Bit::Set module provides a procedural interface to the Bit library. The functions are grouped into several categories for clarity, as described below.
Unless stated otherwise, these functions work either with bitsets (which are Perl scalars holding pointers to C structures of type Bit_T), or with references to such scalars. Hence you will frequently see either the pattern

    my $bitset = Bit_new(1024);
    Bit_bset($bitset, 42);

or the pattern

    my $bitset = Bit_new(1024);
    Bit_bset(\$bitset, 42);

in the examples below. Both patterns are valid, and the choice between them is a matter of application style.

=head2 Creation and Destruction

=over 4

=item B<Bit_new(length)>

Creates a new bitset with the specified capacity (=length) in bits.

=item B<Bit_free(set_ref)>

Frees the memory associated with the bitset. Expects a reference to the scalar holding the bitset. The C function returns the address of the storage
if allocated externally, or NULL if the bitset was allocated by the library.
These values are NOT returned to the Perl caller (so if you used an externally allocated buffer, you need to manage its memory yourself).

=item B<Bit_load(length, buffer)>

Loads an externally allocated bitset into a new Bit_T structure in C and returns it as a Perl scalar. The buffer is provided as a Perl scalar that holds the address of the buffer.

=item B<Bit_extract(set, buffer)>

Extracts the bitset from a Bit_T into an externally allocated buffer.
The buffer is provided as a Perl scalar that holds the address of the buffer.


=back

=head2 Properties

=over 4

=item B<Bit_buffer_size(length)>

Returns the number of bytes needed to store a bitset of given length.

=item B<Bit_length(set)>

Returns the length (capacity) of the bitset in bits.

=item B<Bit_count(set)>

Returns the population count (number of set bits) of the bitset.

=back

=head2 Manipulation

=over 4

=item B<Bit_aset(set, indices)>

Sets an array of bits specified by indices (provided as a reference to a Perl array).

=item B<Bit_bset(set, index)>

Sets a single bit at the specified index to 1.

=item B<Bit_aclear(set, indices)>

Clears an array of bits specified by indices (provided as a reference to an array).

=item B<Bit_bclear(set, index)>

Clears a single bit at the specified index to 0.

=item B<Bit_clear(set, lo, hi)>

Clears a range of bits from lo to hi (inclusive).

=item B<Bit_get(set, index)>

Returns the value of the bit at the specified index.

=item B<Bit_not(set, lo, hi)>

Inverts a range of bits from lo to hi (inclusive).

=item B<Bit_put(set, n, val)>

Sets the nth bit to val and returns the previous value.

=item B<Bit_set(set, lo, hi)>

Sets a range of bits from lo to hi (inclusive) to 1.

=back

=head2 Comparisons

=over 4

=item B<Bit_eq(s, t)>

Returns 1 if bitsets s and t are equal, 0 otherwise.

=item B<Bit_leq(s, t)>

Returns 1 if bitset s is a subset of or equal to t, 0 otherwise.

=item B<Bit_lt(s, t)>

Returns 1 if bitset s is a proper subset of t, 0 otherwise.

=back

=head2 Set Operations

=over 4

=item B<Bit_diff(s, t)>

Returns a new bitset containing the difference of s and t.

=item B<Bit_inter(s, t)>

Returns a new bitset containing the intersection of s and t.

=item B<Bit_minus(s, t)>

Returns a new bitset containing the symmetric difference of s and t.

=item B<Bit_union(s, t)>

Returns a new bitset containing the union of s and t.

=back

=head2 Set Operation Counts

=over 4

=item B<Bit_diff_count(s, t)>

Returns the population count of the difference of s and t without 
creating a new bitset.

=item B<Bit_inter_count(s, t)>

Returns the population count of the intersection of s and t without 
creating a new bitset.

=item B<Bit_minus_count(s, t)>

Returns the population count of the symmetric difference of s and t 
without 
creating a new bitset.

=item B<Bit_union_count(s, t)>

Returns the population count of the union of s and t without 
creating a new bitset.

=back



=head1 EXAMPLES

Examples of the use of the C<Bit::Set> module. Many of these examples are lifted 
from the test suite. Others are Perl "translations" of the original C benchmarks.

=over 4

=item Example 1: Creating and using a bitset

Simple example in which we create, set and test for setting of individual 
bits into a bitset.

  use Bit::Set qw(:all);

  my $bitset = Bit_new(64);
  Bit_bset($bitset, 1);
  Bit_bset(\$bitset, 3);
  Bit_bset($bitset, 5);

  print "Bit 1 is ", Bit_get($bitset, 1) ? "set" : "not set", "\n";
  print "Bit 2 is ", Bit_get($bitset, 2) ? "set" : "not set", "\n";
  print "Bit 3 is ", Bit_get($bitset, 3) ? "set" : "not set", "\n";

  Bit_free(\$bitset);

=item Example 2: Comparison operations between bitsets

This example illustrates the use of the comparison functions provided by the 
C<Bit::Set> module. The equality comparison function is shown for simplicity, but the example can serve as blue print for other comparisons functions e.g. less than equal to.

    use Test::More;  # Convenient testing framework
    use Bit::Set     qw(:all);
    use FFI::Platypus::Buffer;    

    use constant SIZE_OF_TEST_BIT => 65536;
    my $bit1 = Bit_new(SIZE_OF_TEST_BIT);
    my $bit2 = Bit_new(SIZE_OF_TEST_BIT);

    Bit_bset( $bit1, 1 );
    Bit_bset( $bit1, 3 );

    Bit_bset( $bit2, 1 );
    Bit_bset( $bit2, 3 );

    ok( Bit_eq( \$bit1, $bit2 ), 'Bit_eq returns true for equal bitsets' );

    Bit_bset( $bit2, 8 );
    ok( !Bit_eq( $bit1, $bit2 ), 'Bit_eq returns false for unequal bitsets' );

=item Example 3: Set operations on bitsets

This example demonstrates the use of set operations provided by the 
C<Bit::Set> module. In this example, we will form the union of two bitsets 
into a new bitset. Then we will make sure that the union bitset contains 
all the bits from both original bitsets.

    use Test::More;  # Convenient testing framework
    use Bit::Set     qw(:all);

    use constant SIZE_OF_TEST_BIT => 65536;
    my $bit1 = Bit_new(SIZE_OF_TEST_BIT);
    my $bit2 = Bit_new(SIZE_OF_TEST_BIT);

    Bit_bset( $bit1, 1 );
    Bit_bset( $bit1, 3 );

    Bit_bset( $bit2, 3 );
    Bit_bset( $bit2, 5 );

    my $union_bit = Bit_union( $bit1, $bit2 );

    my $union_success =
      (      Bit_get( $union_bit, 1 ) == 1
          && Bit_get( $union_bit, 3 ) == 1
          && Bit_get( $union_bit, 5 ) == 1
          && Bit_get( $union_bit, 0 ) == 0
          && Bit_get( $union_bit, 2 ) == 0
          && Bit_get( $union_bit, 4 ) == 0 );

    ok( $union_success, 'Bit_union works correctly' );

    Bit_free( \$bit1 );
    Bit_free( \$bit2 );
    Bit_free( \$union_bit );

=item Example 4: Count of operations between two sets

In this examples, we illustrate the use of counts of operations between 
two bitsets *inplace*, i.e. without forming the result of the operation 
as a bitset, followed by taking the count.
These operations take advantage of hardware accelerated population counts,
or advanced, SIMD accelerated algorithms for efficient population counting.

    use Test::More;  # Convenient testing framework
    use Bit::Set     qw(:all);

    use constant SIZE_OF_TEST_BIT => 65536;
    my $bit1 = Bit_new(SIZE_OF_TEST_BIT);
    my $bit2 = Bit_new(SIZE_OF_TEST_BIT);

    Bit_bset( $bit1, 1 );
    Bit_bset( \$bit1, 3 );
    Bit_bset( $bit1, 5 );

    Bit_bset( $bit2, 3 );
    Bit_bset( $bit2, 5 );
    Bit_bset( \$bit2, 7 );

    # Set extra bits to test final bits
    my $num_of_final_bits = SIZE_OF_TEST_BIT - 8;
    for my $i ( 8 .. SIZE_OF_TEST_BIT - 1 ) {
        Bit_bset( $bit1, $i );
        Bit_bset( $bit2, $i );
    }

    my $union_count = Bit_union_count( $bit1, $bit2 );
    my $inter_count = Bit_inter_count( $bit1, $bit2 );
    my $minus_count = Bit_minus_count( $bit1, $bit2 );
    my $diff_count  = Bit_diff_count( $bit1, $bit2 );

    my $count_success =
      (      $union_count == 4 + $num_of_final_bits
          && $inter_count == 2 + $num_of_final_bits
          && $minus_count == 1
          && $diff_count == 2 );

    ok( $count_success, 'All count operations work correctly' );

    Bit_free( \$bit1 );
    Bit_free( \$bit2 );

=item Example 5: Loading and extracting a bitset

A slightly more complex example, in which we create a bitset, set a few bits,
 extract them into a buffer (allocated via L<FFI::Platypus::Buffer|https://metacpan.org/pod/FFI::Platypus::Buffer>, though other
 possibilities exist e.g. through L<Task::MemManager|https://metacpan.org/pod/Task::MemManager>) and then checking that their
 values is correct. The load example logic is as follows: first, we allocate the
 buffer, then we set its value using pack, and finaly we put the buffer into a bitset and test the  individual bits.

    use Test::More; # Convenient testing framework
    use Bit::Set     qw(:all);
    use FFI::Platypus::Buffer;    

    use constant SIZE_OF_TEST_BIT => 65536;
    my $bitset = Bit_new(SIZE_OF_TEST_BIT);
    Bit_bset( $bitset, 2 );
    Bit_bset( $bitset, 0 );

    my $buffer_size = Bit_buffer_size(SIZE_OF_TEST_BIT);
    my $scalar =
      "\0" x $buffer_size;    
    my ( $buffer, $size ) =
      scalar_to_buffer $scalar;    
    my $bytes =
      Bit_extract( $bitset, $buffer );   

    my $first_byte = unpack( 'C', substr( $scalar, 0, 1 ) );
    is( $first_byte, 0b00000101, 'Bit_extract produces correct buffer' );
    Bit_free( \$bitset );

    # test_bit_load
    $scalar =
      "\0" x $buffer_size;    
    ( $buffer, $size ) =
      scalar_to_buffer $scalar;    

    substr( $scalar, 0, 1 ) = pack( 'C', 0b00000101 );
    $bitset = Bit_load( SIZE_OF_TEST_BIT, $buffer );

    my $load_success =
      ( Bit_get( $bitset, 0 ) == 1 && Bit_get( $bitset, 2 ) == 1 );
    ok( $load_success, 'Bit_load creates bitset from buffer correctly' );
    Bit_free( \$bitset );

=item Example 6: Benchmarking of the Perl interface to the Bit library

This example re-implements part of the C benchmarking suite for the Bit library
(found in the source file "benchmark.c" in the L<github repository for Bit|https://github.com/chrisarg/Bit>). The goal is to compare the performance of various bitset operations in Perl with their C counterparts, while showing a larger application that uses the Perl interface to the Bit library.
In this example we profile the time it takes to execute the intersection and the
count of the two intersection of two bitsets with variable capacity, ranging from 128 to 1048576 bits. The intersection and the count of the intersection is executed 1000 times and the time it takes to finish this benchmark is used to infer the performance characteristics (nanoseconds per iteration, iteration per second)  of the Perl implementation compared to the C implementation. 
There is negligible overhead introduced by the Perl interface, making it a viable option for performance-critical applications, without the "pain" of writing an application in C.
The github repo L<benchmarking-bits|https://github.com/chrisarg/benchmarking-bits> contains an extensive benchmarking suite that compares the performance of the FFI and XS implementations of both the procedural and the OO interfaces of the Bit::Set module against the C implementation of the Bit library.

    use strict;
    use warnings;
    use Time::HiRes  qw(gettimeofday tv_interval);
    use Bit::Set     qw(:all);

    # Constants
    use constant BPQW => 64;    # bits per qword (8 bytes * 8 bits)
    use constant BPB  => 8;     # bits per byte


    # Test sizes and iterations
    my @size_array = (
        128,   256,   512,    1024,   2048,   4096, 8192, 16384,
        32768, 65536, 131072, 262144, 524288, 1048576
    );
    my $iterations = 1000;

    # Benchmark function registry
    my %benchmark_funcs = (
        'Count' => {
            code  => \&benchmark_bit_count,
            descr => 'Count the number of bits set in the bitset'
        },
        'Inter Count' => {
            code  => \&benchmark_bit_inter_count,
            descr => 'Count the number of bits set in an intersection'
        },
    );

    print "Benchmarking the Perl Bit::Set library\n";
    print "=" x 50, "\n";
    for my $test ( sort keys %benchmark_funcs ) {
        printf "%-15s => %s\n", $test, $benchmark_funcs{$test}{descr};
    }
    print "\n";



    # Benchmark functions for each test type
    sub benchmark_bit_count {
        my ($size) = @_;

        # Pre-create bitsets outside the benchmark
        my $bit1 = Bit_new($size);
        Bit_set( $bit1, int( $size / 2 ), $size - 1 );
        Bit_bset( $bit1, 0 );

        my $t0         = [gettimeofday];
        my $result     = Bit_count($bit1) for 1 .. $iterations;
        my $t1         = [gettimeofday];
        my $total_time = tv_interval $t0, $t1;

        Bit_free( \$bit1 );

        return $total_time;
    }

    sub benchmark_bit_inter_count {
        my ($size) = @_;

        # Pre-create bitsets outside the benchmark
        my $bit1 = Bit_new($size);
        my $bit2 = Bit_new($size);
        Bit_set( $bit1, int( $size / 2 ), $size - 1 );
        Bit_bset( $bit1, 0 );

        my $t0         = [gettimeofday];
        my $result     = Bit_inter_count( $bit1, $bit2 ) for 1 .. $iterations;
        my $t1         = [gettimeofday];
        my $total_time = tv_interval $t0, $t1;

        Bit_free( \$bit1 );
        Bit_free( \$bit2 );

        return $total_time;

    }

    sub run_benchmark {
        my ( $test_name, $size, $benchmark_func ) = @_;

        my $total_time = $benchmark_func->($size);

        my $total_time_ns = $total_time * 1_000_000_000;    # Convert to nanoseconds

        # Calculate derived metrics
        my $time_per_iteration    = $total_time_ns / $iterations;
        my $iterations_per_second = $iterations / $total_time;

        # Format and print results
        printf
        "%-30s (size = %8d): %12.0f ns total\t%8.2f ns/iter\t%10.2e iter/s\n",
        "Bit $test_name", $size, $total_time_ns, $time_per_iteration,
        $iterations_per_second;
    }

    # Main benchmark execution
    print "Running individual benchmarks...\n";
    print "=" x 80, "\n";

    for my $test_name ( sort keys %benchmark_funcs ) {
        print "\nBenchmarking $test_name: $benchmark_funcs{$test_name}{descr}\n";
        print "-" x 80, "\n";
        for my $size (@size_array) {
            run_benchmark( $test_name, $size, $benchmark_funcs{$test_name}{code} );
        }

    }

    print "\n\nBenchmark completed!\n";

=back


=head1 SEE ALSO

=over 4

=item L<Alien::Bit|https://metacpan.org/pod/Alien::Bit>

This distribution provides the library Bit so that it can be used by other Perl 
distributions that are on CPAN. It will download Bit from Github and will build 
the (static and dynamic) versions of the library for use by other Perl modules.

=item L<benchmarking-bits|https://github.com/chrisarg/benchmarking-bits>

A collection of benchmarking scripts for various bitset libraries in C and Perl.

=item L<Bit|https://github.com/chrisarg/Bit>

Bit is a high-performance, uncompressed bitset implementation in C, optimized 
for modern architectures. The library provides an efficient way to create, 
manipulate, and query bitsets with a focus on performance and memory alignment. 
The API and the interface is largely based on David Hanson's Bit_T library 
discussed in Chapter 13 of "C Interfaces and Implementations", 
Addison-Wesley ISBN 0-201-49841-3 extended to incorporate additional operations 
(such as counts on unions/differences/intersections of sets), 
fast population counts using the libpocnt library and GPU operations for packed 
containers of (collections) of Bit(sets).

=item L<Bit::Set::OO|https://metacpan.org/pod/Bit::Set::OO>

Object Oriented interface to the Bit::Set module.

=item L<Bit::Set::DB|https://metacpan.org/pod/Bit::Set::DB>

Procedural interface to the containerized operations of the Bit library.

=item L<Bit::Set::DB::OO|https://metacpan.org/pod/Bit::Set::DB::OO>

Object Oriented interface to the Bit::Set::DB module.

=item L<Bit::Vector|https://metacpan.org/pod/Bit::Vector>

Efficient bit vector, set of integers and "big int" math library

=item L<Lucy::Object::BitVector|https://metacpan.org/dist/Lucy/view/lib/Lucy/Object/BitVector.pod>

Bit vector implementation used in the L<Lucy|https://metacpan.org/pod/Lucy> search engine library.

=back

=head1 TO DO

=over 4


=item B<OpenMP acceleration of operations of arrays of Bit::Set>

Explore the use of Inline::C or straightforward XS with OpenMP support to accelerate operations on arrays of Bit::Set objects. This would be particularly useful in data-intensive applications where multiple bitsets need to be processed in parallel, leveraging multi-core processors for improved performance. This could provide an alternative interface to the containerized operations provided by Bit::Set::DB.

=back

=head1 AUTHOR

Christos Argyropoulos and Joe Schaefer after v0.11.
Christos Argyropoulos with asistance from Github Copilot (Claude Sonnet 4) up to v0.10.

=head1 COPYRIGHT AND LICENSE

This software up to and including v0.10 is copyright (c) 2025 Christos Argyropoulos.
For versions after v0.10, the distribution as a whole is copyright (c) 2025 Joe Schaefer and Christos Argyropoulos.

This software is released under the L<MIT license|https://mit-license.org/>.

=cut
