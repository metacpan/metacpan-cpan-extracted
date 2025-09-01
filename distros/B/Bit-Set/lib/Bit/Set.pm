#!/home/chrisarg/perl5/perlbrew/perls/current/bin/perl
package Bit::Set;
$Bit::Set::VERSION = '0.01';
use strict;
use warnings;
use FFI::Platypus;
use Alien::Bit;


# Set up the FFI object
my $ffi = FFI::Platypus->new( api => 2 );
$ffi->lib( Alien::Bit->dynamic_libs );

# Define opaque types
$ffi->type( 'opaque' => 'Bit_T' );

# LLM did not create an opaque pointer to a pointer
$ffi->type( 'opaque*' => 'Bit_T_Ptr' );

# Define a helper for debug checks that can be stripped at compile time
# LLM provided this: use constant DEBUG => $ENV{DEBUG};
BEGIN {
    use constant DEBUG => $ENV{DEBUG} // 0;
    if (DEBUG) {
        print "* Debugging is enabled\n";
    }
}

# Function definitions for FFI attachment - table-driven approach
my %functions = (

    # Creation / Destruction / Properties
    Bit_new => {
        args  => ['int'],
        ret   => 'Bit_T',
        check => sub {
            my ($length) = @_;
            die "Bit_new: length must be >= 0 and <= INT_MAX"
              if $length < 0 || $length > 2147483647;
        }
    },
    Bit_free => {
        args => ['Bit_T_Ptr'],
        ret  => 'opaque',
    },
    Bit_load => {
        args  => [ 'int', 'opaque' ],
        ret   => 'Bit_T',
        check => sub {
            my ( $length, $buffer ) = @_;
            die "Bit_load: length must be >= 0 and <= INT_MAX"
              if $length < 0 || $length > 2147483647;
            die "Bit_load: buffer cannot be NULL" if !defined $buffer;
        }
    },
    Bit_extract => {
        args  => [ 'Bit_T', 'opaque' ],
        ret   => 'int',
        check => sub {
            my ( $set, $buffer ) = @_;
            die "Bit_extract: set cannot be NULL"    if !defined $set;
            die "Bit_extract: buffer cannot be NULL" if !defined $buffer;
        }
    },
    Bit_buffer_size => {
        args  => ['int'],
        ret   => 'int',
        check => sub {
            my ($length) = @_;
            die "Bit_buffer_size: length must be >= 0 and <= INT_MAX"
              if $length < 0 || $length > 2147483647;
        }
    },
    Bit_length => {
        args  => ['Bit_T'],
        ret   => 'int',
        check => sub {
            my ($set) = @_;
            die "Bit_length: set cannot be NULL" if !defined $set;
        }
    },
    Bit_count => {
        args  => ['Bit_T'],
        ret   => 'int',
        check => sub {
            my ($set) = @_;
            die "Bit_count: set cannot be NULL" if !defined $set;
        }
    },

    # Manipulation functions
    Bit_aset => {
        args  => [ 'Bit_T', 'int[]', 'int' ],
        ret   => 'void',
        check => sub {
            my ( $set, $indices, $n ) = @_;
            die "Bit_aset: set cannot be NULL"           if !defined $set;
            die "Bit_aset: indices array cannot be NULL" if !defined $indices;
            die "Bit_aset: n must be >= 0"               if $n < 0;
        }
    },
    Bit_bset => {
        args  => [ 'Bit_T', 'int' ],
        ret   => 'void',
        check => sub {
            my ( $set, $index ) = @_;
            die "Bit_bset: set cannot be NULL" if !defined $set;
            die "Bit_bset: index must be >= 0" if $index < 0;
        }
    },
    Bit_aclear => {
        args  => [ 'Bit_T', 'int[]', 'int' ],
        ret   => 'void',
        check => sub {
            my ( $set, $indices, $n ) = @_;
            die "Bit_aclear: set cannot be NULL"           if !defined $set;
            die "Bit_aclear: indices array cannot be NULL" if !defined $indices;
            die "Bit_aclear: n must be >= 0"               if $n < 0;
        }
    },
    Bit_bclear => {
        args  => [ 'Bit_T', 'int' ],
        ret   => 'void',
        check => sub {
            my ( $set, $index ) = @_;
            die "Bit_bclear: set cannot be NULL" if !defined $set;
            die "Bit_bclear: index must be >= 0" if $index < 0;
        }
    },
    Bit_clear => {
        args  => [ 'Bit_T', 'int', 'int' ],
        ret   => 'void',
        check => sub {
            my ( $set, $lo, $hi ) = @_;
            die "Bit_clear: set cannot be NULL" if !defined $set;
            die "Bit_clear: lo must be >= 0"    if $lo < 0;
            die "Bit_clear: hi must be >= lo"   if $hi < $lo;
        }
    },
    Bit_get => {
        args  => [ 'Bit_T', 'int' ],
        ret   => 'int',
        check => sub {
            my ( $set, $index ) = @_;
            die "Bit_get: set cannot be NULL" if !defined $set;
            die "Bit_get: index must be >= 0" if $index < 0;
        }
    },
    Bit_not => {
        args  => [ 'Bit_T', 'int', 'int' ],
        ret   => 'void',
        check => sub {
            my ( $set, $lo, $hi ) = @_;
            die "Bit_not: set cannot be NULL" if !defined $set;
            die "Bit_not: lo must be >= 0"    if $lo < 0;
            die "Bit_not: hi must be >= lo"   if $hi < $lo;
        }
    },
    Bit_put => {
        args  => [ 'Bit_T', 'int', 'int' ],
        ret   => 'int',
        check => sub {
            my ( $set, $n, $val ) = @_;
            die "Bit_put: set cannot be NULL" if !defined $set;
            die "Bit_put: n must be >= 0"     if $n < 0;
        }
    },
    Bit_set => {
        args  => [ 'Bit_T', 'int', 'int' ],
        ret   => 'void',
        check => sub {
            my ( $set, $lo, $hi ) = @_;
            die "Bit_set: set cannot be NULL" if !defined $set;
            die "Bit_set: lo must be >= 0"    if $lo < 0;
            die "Bit_set: hi must be >= lo"   if $hi < $lo;
        }
    },

    # Comparison functions
    Bit_eq => {
        args  => [ 'Bit_T', 'Bit_T' ],
        ret   => 'int',
        check => sub {
            my ( $s, $t ) = @_;
            die "Bit_eq: bitsets cannot be NULL" if !defined $s || !defined $t;
        }
    },
    Bit_leq => {
        args  => [ 'Bit_T', 'Bit_T' ],
        ret   => 'int',
        check => sub {
            my ( $s, $t ) = @_;
            die "Bit_leq: bitsets cannot be NULL" if !defined $s || !defined $t;
        }
    },
    Bit_lt => {
        args  => [ 'Bit_T', 'Bit_T' ],
        ret   => 'int',
        check => sub {
            my ( $s, $t ) = @_;
            die "Bit_lt: bitsets cannot be NULL" if !defined $s || !defined $t;
        }
    },

    # Set operations
    Bit_diff => {
        args  => [ 'Bit_T', 'Bit_T' ],
        ret   => 'Bit_T',
        check => sub {
            my ( $s, $t ) = @_;
            die "Bit_diff: bitsets cannot be NULL"
              if !defined $s || !defined $t;
        }
    },
    Bit_inter => {
        args  => [ 'Bit_T', 'Bit_T' ],
        ret   => 'Bit_T',
        check => sub {
            my ( $s, $t ) = @_;
            die "Bit_inter: bitsets cannot be NULL"
              if !defined $s || !defined $t;
        }
    },
    Bit_minus => {
        args  => [ 'Bit_T', 'Bit_T' ],
        ret   => 'Bit_T',
        check => sub {
            my ( $s, $t ) = @_;
            die "Bit_minus: bitsets cannot be NULL"
              if !defined $s || !defined $t;
        }
    },
    Bit_union => {
        args  => [ 'Bit_T', 'Bit_T' ],
        ret   => 'Bit_T',
        check => sub {
            my ( $s, $t ) = @_;
            die "Bit_union: bitsets cannot be NULL"
              if !defined $s || !defined $t;
        }
    },

    # Set operation counts
    Bit_diff_count => {
        args  => [ 'Bit_T', 'Bit_T' ],
        ret   => 'int',
        check => sub {
            my ( $s, $t ) = @_;
            die "Bit_diff_count: bitsets cannot be NULL"
              if !defined $s || !defined $t;
        }
    },
    Bit_inter_count => {
        args  => [ 'Bit_T', 'Bit_T' ],
        ret   => 'int',
        check => sub {
            my ( $s, $t ) = @_;
            die "Bit_inter_count: bitsets cannot be NULL"
              if !defined $s || !defined $t;
        }
    },
    Bit_minus_count => {
        args  => [ 'Bit_T', 'Bit_T' ],
        ret   => 'int',
        check => sub {
            my ( $s, $t ) = @_;
            die "Bit_minus_count: bitsets cannot be NULL"
              if !defined $s || !defined $t;
        }
    },
    Bit_union_count => {
        args  => [ 'Bit_T', 'Bit_T' ],
        ret   => 'int',
        check => sub {
            my ( $s, $t ) = @_;
            die "Bit_union_count: bitsets cannot be NULL"
              if !defined $s || !defined $t;
        }
    },
);

# Attach all functions
for my $name ( sort keys %functions ) {
    my $spec        = $functions{$name};
    my @attach_args = ( $name, $spec->{args}, $spec->{ret} );

    if (DEBUG)
    { ##  if (DEBUG && exists $spec->{check}) { -> LLM version, break into nested ifs
        if ( exists $spec->{check} ) {
            my $checker = $spec->{check};

        # version returned by the LLM
        #            push @attach_args, wrapper => sub { # as created by the LLM
        #                my $orig = shift;
        #                $checker->(@_);
        #                return $orig->(@_);
        #            };

            push @attach_args, sub {
                my $orig = shift;
                $checker->(@_);
                return $orig->(@_);
            };
        }
    }
    $ffi->attach(@attach_args);
}

# Verification that all C functions are mapped (excluding macros and Bit_map)
my @c_functions = qw(
  Bit_new Bit_free Bit_load Bit_extract Bit_buffer_size Bit_length Bit_count
  Bit_aset Bit_bset Bit_aclear Bit_bclear Bit_clear Bit_get Bit_not Bit_put Bit_set
  Bit_eq Bit_leq Bit_lt
  Bit_diff Bit_inter Bit_minus Bit_union
  Bit_diff_count Bit_inter_count Bit_minus_count Bit_union_count
);

my %perl_functions;
@perl_functions{ keys %functions } = ();
for my $c_func (@c_functions) {
    die "FATAL: C function '$c_func' not implemented in Bit::Set"
      unless exists $perl_functions{$c_func};
}

# LLM forgot to export the Bit::Set functions
use Exporter 'import';
our @EXPORT_OK   = keys %functions;
our %EXPORT_TAGS = ( all => [@EXPORT_OK] );

1;

__END__

=head1 NAME

Bit::Set - Perl interface for bitset functions from the 'bit' C library

=head1 VERSION

version 0.01

=head1 SYNOPSIS

  use Bit::Set;

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

This module provides a procedural Perl interface to the C library 'bit.h',
for creating and manipulating bitsets. It uses C<FFI::Platypus> to wrap the
C functions and C<Alien::Bit> to locate and link to the C library.

The API is a direct mapping of the C functions. For detailed semantics of each
function, please refer to the C<bit.h> header file documentation.

Runtime checks on arguments are performed if the C<DEBUG> environment variable
is set to a true value when installing the code.

The module was created during a "vibecoding" experiment in Github Copilot
running through the VS Code editor. The section VIBECODING A FFI API of
the documentation discusses the prompts used to generate the FFI bindings, and
the manual edits of the generated code. While I went through various iterations
of the prompt, only the final one is provided (and documented). It is estimated
that somewhere between 20-30 hours of "vibecoding" (prompt authoring, refinement,
verification of the output and exploration of various chatbots) went into the 
creation of this module. Unless stated otherwise, the source code of the module 
retains the original output as returned by the chatbot. In the case that manual
edits were made to the generated code, the original output has been retained 
in the comments of the module code. Some (but not all!) noteworthy edits are
discussed in the documentation.


=head1 FUNCTIONS

=head2 Creation and Destruction

=over 4

=item B<Bit_new(length)>

Creates a new bitset with the specified capacity (=length) in bits.

=item B<Bit_free(set_ref)>

Frees the memory associated with the bitset. Expects a reference to the scalar holding the bitset.

=item B<Bit_load(length, buffer)>

Loads an externally allocated bitset into a new Bit_T structure.

=item B<Bit_extract(set, buffer)>

Extracts the bitset from a Bit_T into an externally allocated buffer.
Look at EXAMPLES for usage of the load and extract functions using FFI::Platypus.

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

=item B<Bit_aset(set, indices, n)>

Sets an array of bits specified by indices.

=item B<Bit_bset(set, index)>

Sets a single bit at the specified index to 1.

=item B<Bit_aclear(set, indices, n)>

Clears an array of bits specified by indices.

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

Examples of the use of the Bit::Set module. Many of these examples are lifted 
from the test suite.
Others are Perl "translations" of the original C benchmarks.

=over 4

=item Example 1: Creating and using a bitset

Simple example in which we create, set and test for setting of individual 
bits into a bitset.

  use Bit::Set;

  my $bitset = Bit_new(64);
  Bit_set($bitset, 1);
  Bit_set($bitset, 3);
  Bit_set($bitset, 5);

  print "Bit 1 is ", Bit_get($bitset, 1) ? "set" : "not set", "\n";
  print "Bit 2 is ", Bit_get($bitset, 2) ? "set" : "not set", "\n";
  print "Bit 3 is ", Bit_get($bitset, 3) ? "set" : "not set", "\n";

  Bit_free(\$bitset);

=item Example 2: Comparison operations between bitsets

This example illustrates the use of the comparison functions provided by the 
Bit::Set module. The equality comparison function is shown for simplicity, but 
the example can serve as blue print for
other comparisons functions e.g. less than equal to.

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

    ok( Bit_eq( $bit1, $bit2 ), 'Bit_eq returns true for equal bitsets' );

    Bit_bset( $bit2, 8 );
    ok( !Bit_eq( $bit1, $bit2 ), 'Bit_eq returns false for unequal bitsets' );

=item Example 3: Set operations on bitsets

This example demonstrates the use of set operations provided by the 
Bit::Set module. In this example, we will form the union of two bitsets 
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
    Bit_bset( $bit1, 3 );
    Bit_bset( $bit1, 5 );

    Bit_bset( $bit2, 3 );
    Bit_bset( $bit2, 5 );
    Bit_bset( $bit2, 7 );

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
 extract them into a buffer (allocated via FFI::Platypus::Buffer, though other
 possibilities exist e.g. through Task::MemManager) and then checking that their
 values is correct. The load example reverses the logic, i.e. we allocate the
 buffer, set its value using pack, put the buffer into a bitset and test the
 individual bits.

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
(found in the source file "benchmark.c" in the github repository for Bit). The
goal is to compare the performance of various bitset operations in Perl with their
C counterparts, while showing a larger application that uses the Perl interface
to the Bit library.
In this example we profile the time it takes to execute the intersection and the
count of the two intersection of two bitsets with variable capacity, ranging from 
128 to 1048576 bit. The intersection and the count of the intersection is executed
1000 times and the time it takes to finish this benchmark is used to infer the
performance characteristics (nanoseconds per iteration, iteration per second) 
of the Perl implementation compared to the C implementation. 
There is negligible overhead introduced by the Perl interface, making it a viable
option for performance-critical applications, without the "pain" of writing an
application in C.

    use strict;
    use warnings;
    use Time::HiRes  qw(gettimeofday tv_interval);
    use Bit::Set     qw(:all);
    use Bit::Set::DB qw(:all);

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

=head1 VIBECODING A FFI API

The module was created during a "vibecoding" experiment in Github Copilot
running through the VS Code editor. During the initial exploration, which lasted
approximately 20 hours, I tried most agents available through VS Code at the time
of this writing (late August - early September 2025), and did not find much 
of a difference. I ultimately settled for Claude 4.0, since the Claude 3.7
Thinking model had been used in my "vibecoding" GitHub page posts:

L<Vibe coding a Perl interface to a foreign library- Part 1|https://chrisarg.github.io/Killing-It-with-PERL/2025/06/30/Vibe-coding-a-Perl-interface-to-a-foreign-library-Part-1.html>
L<Vibe coding a Perl interface to a foreign library - Part 2|https://chrisarg.github.io/Killing-It-with-PERL/2025/07/04/Vibe-coding-a-Perl-interface-to-a-foreign-library-Part-2.html>

In these explorations, agentic LLMs were found particularly problematic, often 
stalling to generate a solution, focusing on the wrong thing when tests were
failing and often giving up. I therefore ended up not using them, and relied 
on the "Ask" mode of Github Copilot.

To build this module, I first created the distribution structure with (what else?)
L<Dist::Zilla|https://metacpan.org/pod/Dist::Zilla>, and then opened the folder
using VS Code. Subsequently, I provided as context the "bit.h" header file from
the L<Bit library|https://github.com/chrisarg/Bit> and the associated README
markdown file. The prompt used was the following:

    Forget everything I have said and your responses so far. Look at the description 
    of the project in README.md and the Abstract Data Type interface in bit.h. 
    Put your self in the place of a senior Perl engineer with extensive understanding
    of the C language. Your goal is to create a procedural Perl API to all the 
    functions in C using the Foreign Function Interface. Assume that we have already 
    implemented an Alien module (Alien::Bit) to install the foreign (C) dependency 
    bit, so make sure you use it! Look at the checked runtime exceptions in the 
    documentation of the C interface. Your goal is to incorporate them in the Perl 
    interface too, as long as the user has set the DEBUG environmental variable. 
    If the DEBUG variable has not been set, these runtime checks should be stripped 
    during the compile phase of the PERL program. To do so, please ensure that the 
    relevant check involves ONLY DEBUG, otherwise the code may not be stripped.
    Things to adhere to during the implementation:

    The functions for the Bit_T, should end up in the module Bit::Set, and those for 
    Bit_DB to Bit::Set::DB .
    1. Ensure that you implement the Perl interface to all the functions in the C 
    interface, i.e. don't implement some functions and then tell me the others are 
    implemented similarly! Reflect that you have implemented all the functions by 
    comparing the functions that are exported by the Perl module against the 
    functions declared in the bit.h interface (excluding of course the functions 
    defined as macros).
    2. The names of the methods in the Perl interface should match those of the C 
    interface exactly, without exceptions. However, you should not implement the 
    map function(s).
    3. When implementing the wrapper, combine a table driven approach with the 
    FFI's attach to maximize conciseness and reduct repetition of the code. 
    For example, you may want to use a hash with keys the function names that 
    the module will export. CAUTION: As a senior engineer you are probably aware 
    of the DRY principle (Don't Repeat Yourself). When you generate code please 
    balance DRY with the performance penalty of function evaluations (e.g. for checks).
    4. When implementing a function, do provide the POD documentation for it. 
    However, generate the POD after you have implemented the functions.
    5. After you have implemented the modules, generate a simple test that will 
    generate a Bit::Set of capacity of 1024 bits, set the first, second and 5th one 
    and see if the popcount is equal to 3.

Claude did get *most* things right:

=over 4
=item * 
it generated 3 chunks of code corresponding to `Bit::Set`,  `Bit::Set::DB` and the single test file
=item * 
the table driven approach was implemented effectively reducing the number of lines
of code that had to be written
=item * 
The checked runtime exceptions in the C interface were incorporated in the Perl 
using a wrapper function that was provided to `FFI::Platypus` `attach`.
=item *
The `FFI::Platypus::Record` was correctly selected into the implementation for the
C structure that passes options for the CPU/GPU enhanced container functions.
=item * 
the POD documentation was generated as a skeleton using the grouping of function
in the README file. The documentation was no frills, a very simple repetition of
what is available from L<Bit|https://github.com/chrisarg/Bit>, but it is enough to
get one started. 

=back

However, the code itself would not work, requiring a few minor tweaks that are
summarized below:

=over 4

=item 1. Incorporating runtime exceptions

The relevant section is shown below and exhibits numerous problems. 

    for my $name ( sort keys %functions ) {
        my $spec        = $functions{$name};
        my @attach_args = ( $name, $spec->{args}, $spec->{ret} );
        $ffi->attach(@attach_args);
        if ( DEBUG && exists $spec->{check} ) {
            my $checker = $spec->{check};
            push @attach_args, wrapper => sub {    
                my $orig = shift;
                $checker->(@_);
                return $orig->(@_);
            };
        }
    }
When the DEBUG variable is not set, it is unclear whether the check for DEBUG
will strip the code that adds the runtime exception wrapper at compile time.
The pattern discussed in the Perl documentation states that a simple test
of the form `if (DEBUG) { ... }` will strip everything within the block, but
will a test of the form `if ( DEBUG && exists $spec->{check} ) { ... }` do the 
same? 
Secondly, the attachment of the wrapper function to the FFI call is also a 
concern: it takes place early in the process, before the DEBUG check is made.
Thirdly, the snippet `push @attach_args, wrapper => sub { ... }` as it pushes
*two* arguments into the function call for `attach`. 
If one looks into the documentation for L<FFI::Platypus::attach|https://metacpan.org/pod/FFI::Platypus#attach>, 

    $ffi->attach($name => \@argument_types => $return_type);
    $ffi->attach([$c_name => $perl_name] => \@argument_types => $return_type);
    $ffi->attach([$address => $perl_name] => \@argument_types => $return_type);
    $ffi->attach($name => \@argument_types => $return_type, \&wrapper);
    $ffi->attach([$c_name => $perl_name] => \@argument_types => $return_type, \&wrapper);
    $ffi->attach([$address => $perl_name] => \@argument_types => $return_type, \&wrapper);

it becomes clear that the maintainer is using the fat comma instead of the
regular comma to pass consecutive arguments into the `attach` function. 
However, the chatbot is confusing the syntax and adding a hashlike key-value 
pair when pushing the arguments of `attach`.

All these problems are reasonably easy to fix, by breaking the test involving 
DEBUG into two nested ifs, moving the attach invocation at the end of the loop,
and pushing the code reference without the 'wrapper => ' part into the arguments
of the attach function.

=item 2. The fat comma strikes again

The container module (`Bit::Set::DB`) uses a C structure to pass options to the 
CPU/hardware accelerator device . This C structure is passed by value and thus 
should be passed as a `FFI::Platypus::Record`, created either as a separate 
module file, or nested in the `Bit::Set::DB` module. The code that was actually
generated by Claude looked like this:

    {
        package Bit::Set::DB::SETOP_COUNT_OPTS;
        use FFI::Platypus::Record;
        record_layout_1(
        'num_cpu_threads' => 'int',
        'device_id' => 'int',
        'upd_1st_operand' => 'bool',
        'upd_2nd_operand' => 'bool',
        'release_1st_operand' => 'bool',
        'release_2nd_operand' => 'bool',
        'release_counts' => 'bool',
            );
    }

In the documentation for L<FFI::Platypus::Record|https://metacpan.org/pod/FFI::Platypus::Record#record_layout_1>, one can clearly see that the function record_layout_1 
receives arguments as `record_layout_1($type => $name, ... );`, i.e. the fat comma 
is used to separate consecutive arguments to the function, and not as part of the 
definition of a hash. However Claude must "think" that it is dealing with a hash,
as it reverses the order of the arguments to make the "keys" unique.
The fix is rather simple, i.e. one simply reverses the order of the arguments.

=item 3. Forgetting the proper way to register records with FFI

Interestingly enough, the chatbot failed to properly register the type of the 
record with FFI. In the original output, it included the line:
    $ffi->type( 'Bit::Set::DB::SETOP_COUNT_OPTS' => 'SETOP_COUNT_OPTS_t' )

rather than the correct
    $ffi->type( 'record(Bit::Set::DB::SETOP_COUNT_OPTS)' => 'SETOP_COUNT_OPTS_t' )


=back

Having fixed these errors, I proceeded to generate a Perl version of the C
test suite, by providing as context the (fixed) modules : `Bit::Set` and 
`Bit::Set::DB` as well as the C source code for "test_bit.c". The actual
prompt was the single liner:

    Convert this test file written in C to Perl, using the Bit::Set and Bit::Set::DB modules. 

The major problem with this conversion was the failure of the chatbot to
generate correct code when testing the functions that are loading/extracting
information from bitsets or containers into raw buffers. For example the 
following code is supposed to test the extraction of bits from a bitset:

    my $bitset = Bit_new(SIZE_OF_TEST_BIT);
    Bit_bset( $bitset, 2 );
    Bit_bset( $bitset, 0 );

    my $buffer_size = Bit_buffer_size(SIZE_OF_TEST_BIT);
    my $buffer = "\0" x $buffer_size;
    my $bytes = Bit_extract( $bitset, $buffer ); 

    my $first_byte = unpack('C', substr($buffer, 0, 1))
    is( $first_byte, 0b00000101, 'Bit_extract produces correct buffer' );
    Bit_free( \$bitset );

However, the code is utterly wrong (and segfaults!) as one has to provide
the memory address of the buffer, not the Perl scalar value. The fix is to
generate the buffer as a Perl string and then use `FFI::Platypus::Buffer` 
to extract the memory address of the storage buffer used by the Perl scalar:

    my $scalar = "\0" x $buffer_size;    
    my ( $buffer, $size ) = scalar_to_buffer $scalar;   
    my $bytes =  Bit_extract( $bitset, $buffer );  
    my $first_byte = unpack( 'C', substr( $scalar, 0, 1 ) ) ; 

I only had to edit about 6 lines out of ~ 400 to port the C test suite to Perl. 

=head1 SEE ALSO

=over 4

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

item L<Alien::Bit|https://metacpan.org/pod/Alien::Bit>

This distribution provides the library Bit so that it can be used by other Perl 
distributions that are on CPAN. It will download Bit from Github and will build 
the (static and dynamic) versions of the library for use by other Perl modules.

=back

=head1 AUTHOR

GitHub Copilot (Claude Sonnet 4), guided by Christos Argyropoulos.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Christos Argyropoulos.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
