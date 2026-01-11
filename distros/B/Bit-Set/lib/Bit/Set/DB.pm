#!/home/chrisarg/perl5/perlbrew/perls/current/bin/perl
package Bit::Set::DB;
$Bit::Set::DB::VERSION = '0.13';
use strict;
use warnings;
use XSLoader();



# Load the SetDB XS library
XSLoader::load('Bit::Set::DB');

# Also load the XS-based SETOP_COUNT_OPTS class for backward compatibility
use Bit::Set::DB::SETOP_COUNT_OPTS;

my @c_functions = qw(
  BitDB_new BitDB_free BitDB_length BitDB_nelem BitDB_count_at BitDB_count
  BitDB_get_from BitDB_put_at BitDB_extract_from BitDB_replace_at BitDB_clear BitDB_clear_at BitDB_load
  BitDB_inter_count_store_cpu BitDB_union_count_store_cpu BitDB_diff_count_store_cpu BitDB_minus_count_store_cpu
  BitDB_inter_count_store_gpu BitDB_union_count_store_gpu BitDB_diff_count_store_gpu BitDB_minus_count_store_gpu
  BitDB_inter_count_cpu BitDB_union_count_cpu BitDB_diff_count_cpu BitDB_minus_count_cpu
  BitDB_inter_count_gpu BitDB_union_count_gpu BitDB_diff_count_gpu BitDB_minus_count_gpu
);

use Exporter 'import';
our @EXPORT_OK   = @c_functions;
our %EXPORT_TAGS = ( all => [@EXPORT_OK] );

our @EXPORT = qw(BitDB_new BitDB_free);

1;

__END__

=head1 NAME

Bit::Set::DB - Extended XS-based interface for BitDB set operations

=head1 VERSION

version 0.13

=head1 SYNOPSIS

    use Bit::Set::DB;
    
    # Use the main DB interface
    my $DB = Bit::Set::DB->new();
    print "Version: ", $DB->version, "\n";
    
    # Also provides access to SETOP_COUNT_OPTS
    my $opts = Bit::Set::DB::SETOP_COUNT_OPTS->new();
    my $OPTS = Bit::Set::DB::SETOP_COUNT_OPTS->new({
        device_id => 1,
        upd_1st_operand => 1,
        upd_2nd_operand => 0,
        release_1st_operand => 1,
        release_2nd_operand => 1,
        release_counts => 1
    });

=head1 DESCRIPTION

This module provides an extended XS-based interface for BitDB set operations.
It includes both its own XS implementation and access to the SETOP_COUNT_OPTS class.



=head1 SYNOPSIS

  use Bit::Set::DB qw(:all);
  use Bit::Set qw(:all);

  # Create a new bitset database
  my $db = BitDB_new(1024, 10);

  # Create a bitset and add it to the database
  my $set = Bit::Set::Bit_new(1024);
  Bit::Set::Bit_bset($set, 42);
  BitDB_put_at($db, 0, $set);

  # Get population count at index
  my $count = BitDB_count_at($db, 0);
  say $count;                           ## should print 1
  # Free the database and bitset
  BitDB_free(\$db);
  Bit::Set::Bit_free(\$set);

=head1 DESCRIPTION

This module provides a procedural Perl interface to the C library C<Bit>,
for creating and manipulating containers of bitsets (BitDB). It uses
C<XS> to wrap the C functions and C<Alien::Bit> to locate and link
to the C library. The main purpose of this library is to provide multithreaded
and hardware accelerated (e.g. GPU) versions of container operations e.g. forming
the population count of the intersection of two containers of bitsets.

The API is a direct mapping of the C functions. For detailed semantics of each
function, please refer to the C<bit.h> header file documentation.

GPU offloading is disabled if you set up the C<NOGPU> environment variable.
Only the constructor and destructor are exported by default. You can import all functions using the C<:all> tag, or import individual functions as needed.

Unless otherwise noted, the functions accept a Perl scalar that encapsulates the BitDB object, or a reference to such a scalar, e.g. for the most part C<some_func($db)> or C<some_func(\$db)> are interchangeable.


=head1 Functions in the procedural interface

=head2 Creation and Destruction

=over 4

=item B<BitDB_new(length, num_of_bitsets)>

Creates a new bitset container for C<num_of_bitsets> bitsets, each of C<length>.

=item B<BitDB_free(db_ref)>

Frees the memory associated with the bitset container. Expects a reference to the scalar holding the DB object.

=item B<BitDB_load(length, num_of_bitsets, buffer address - numeric)>

Creates a new bitset container for C<num_of_bitsets> bitsets, each of C<length>, from an external buffer. The buffer address should point to a memory region large enough to hold all bitsets.

=back

=head2 Properties

=over 4

=item B<BitDB_length(set)>

Returns the length of bitsets in the container.

=item B<BitDB_nelem(set)>

Returns the number of bitsets in the container.

=item B<BitDB_count_at(set, index)>

Returns the population count of the bitset at the given C<index>.

=item B<BitDB_count(set)>

Returns a pointer to an array of population counts for all bitsets in the container.

=back

=head2 Manipulation

=over 4

=item B<BitDB_get_from(set, index)>

Returns a bitset from the container at the given C<index>.

=item B<BitDB_put_at(set, index, bitset)>

Puts a C<bitset> into the container at the given C<index>.

=item B<BitDB_extract_from(set, index, buffer)>

Extracts a bitset from the container at C<index> into a C<buffer>.

=item B<BitDB_replace_at(set, index, buffer)>

Replaces a bitset in the container at C<index> with the contents of a C<buffer>.

=item B<BitDB_clear(set)>

Clears all bitsets in the container.

=item B<BitDB_clear_at(set, index)>

Clears the bitset at a given C<index> in the container.

=back

=head2 Set Operation Counts

These functions perform set operations between two bitset containers. The C<opts>
parameter is an object of type C<Bit::Set::DB::SETOP_COUNT_OPTS>.

Example for C<opts>:

  my $opts = Bit::Set::DB::SETOP_COUNT_OPTS->new(
      num_cpu_threads => 4,
      device_id       => 0,
      # ... other flags
  );

Perform the respective set operation count on the CPU using 4 threads. If one passes C<device_id> other than 0, the corresponding device will be used. We follow the B<OpenMP> convention where C<N> indicates CPU in a system with N GPU devices, and C<0> to C<N-1> indicates the GPUs.

The following functions perform the respective set operation count on the CPU:
=over 5

=item B<BitDB_inter_count_cpu(db1, DB, opts, ...)>

=item B<BitDB_union_count_cpu(db1, DB, opts, ...)>

=item B<BitDB_diff_count_cpu(db1, DB, opts, ...)>

=item B<BitDB_minus_count_cpu(db1, DB, opts, ...)>

=back

Perform the respective set operation count on the GPU:

=over 5

=item B<BitDB_inter_count_gpu(db1, DB, opts, ...)>

=item B<BitDB_union_count_gpu(db1, DB, opts, ...)>

=item B<BitDB_diff_count_gpu(db1, DB, opts, ...)>

=item B<BitDB_minus_count_gpu(db1, DB, opts, ...)>

=back

The optional C<...> argument is used to determine the type of the returned counts buffer:

=over 6

=item If omitted,undef or zero the function returns a reference to an array of integers containing the counts.

=item If the optional parameter argument value is set to the integer 1, the function will return a pointer to a buffer containing the counts as an array of integers. 

This pointer can be used with the C<Task::MemManager> module to provide a memory leak-free way to manage its lifetime.

=back


Perform the respective set operation count on the CPU and store results in C<buffer>:

=over 5

=item B<BitDB_inter_count_store_cpu(db1, DB, buffer, opts,...)>

=item B<BitDB_union_count_store_cpu(db1, DB, buffer, opts,...)>

=item B<BitDB_diff_count_store_cpu(db1, DB, buffer, opts,...)>

=item B<BitDB_minus_count_store_cpu(db1, DB, buffer, opts,...)>

=back

Perform the respective set operation count on the GPU and store results in C<buffer>:

=over 5

=item B<BitDB_inter_count_store_gpu(db1, DB, buffer, opts,...)>

=item B<BitDB_union_count_store_gpu(db1, DB, buffer, opts,...)>

=item B<BitDB_diff_count_store_gpu(db1, DB, buffer, opts,...)>

=item B<BitDB_minus_count_store_gpu(db1, DB, buffer, opts,...)>

=back

The optional argument C<...> has the same semantics as above.

=head1 EXAMPLES

Examples of the use of the C<Bit::Set::DB> module that emphasize performance
characteristics and nuances of using raw memory buffers that are returned by
the interface. Some of these examples are meant to be run as sequential
units

=over 4

=item Example 1: Creating and initializing containers

In this example, we will create two Perl arrays of C<Bit::Set> and then load
them to C<Bit::Set::DB> containers. 

    use warnings;
    use Bit::Set  qw(:all);
    use Bit::Set::DB qw(:all);

    my $size            = 1024;
    my $num_of_bits     = 3;
    my $num_of_ref_bits = 5;

    my @bits;
    my @bitsets;

    # Initializing and setting the values of the bitsets
    for my $i ( 0 .. $num_of_bits - 1 ) {
        $bits[$i] = Bit_new($size);
        my $end = int( $size / 2 ) + $i;
        $end = ( $end > $size - 1 ) ? $size - 1 : $end;
        Bit_set( $bits[$i], int( $size / 2 ), $end );
    }
    for my $i ( 0 .. $num_of_ref_bits - 1 ) {
        $bitsets[$i] = Bit_new($size);
        my $end = int( $size / 2 ) + $i;
        $end = ( $end > $size - 1 ) ? $size - 1 : $end;
        Bit_set( $bitsets[$i], int( $size / 2 ), $end );
    }
    Bit_set( $bits[0],    int( $size / 2 ) - 1, int( $size / 2 ) + 5 );
    Bit_set( $bitsets[0], int( $size / 2 ),     int( $size / 2 ) + 5 );

    # Create BitDB containers
    my $db1 = BitDB_new( $size, $num_of_bits );
    my $DB = BitDB_new( $size, $num_of_ref_bits );

    # Now put the bitsets into the containers
    for my $i ( 0 .. $num_of_bits - 1 ) {
        BitDB_put_at( $db1, $i, $bits[$i] );
    }
    for my $i ( 0 .. $num_of_ref_bits - 1 ) {
        BitDB_put_at( $DB, $i, $bitsets[$i] );
    }
    
    say "Count : $_" for BitDB_count($db1)->@*;

=item Example 2: Obtaining the counts of bitset operations using containers

This example continues Example 1 by performing the intersection count in two
different ways: 1) iterating over the Perl arrays of bitsets and 2) using the
BitDB containers directly. A major benefit of these containerized operations
is that they can leverage multi-threading in the CPU and hardware acceleration
in GPUs (and TPUs in the near future).
When we use the interface over containers, we will need to interface the integer
array returned by the C<Bit::Set::DB> interface function to Perl arrays.
This is one possible way of doing so using the C<FFI::Platypus::Buffer> and
C<FFI::Platypus::Buffer> modules. 

    use strict;
    use warnings;
    use Bit::Set  qw(:all);
    use Bit::Set::DB qw(:all);

    my $size            = 1024;
    my $num_of_bits     = 3;
    my $num_of_ref_bits = 5;

    my @bits;
    my @bitsets;

    # Initializing and setting the values of the bitsets
    for my $i ( 0 .. $num_of_bits - 1 ) {
        $bits[$i] = Bit_new($size);
        my $end = int( $size / 2 ) + $i;
        $end = ( $end > $size - 1 ) ? $size - 1 : $end;
        Bit_set( $bits[$i], int( $size / 2 ), $end );
    }
    for my $i ( 0 .. $num_of_ref_bits - 1 ) {
        $bitsets[$i] = Bit_new($size);
        my $end = int( $size / 2 ) + $i;
        $end = ( $end > $size - 1 ) ? $size - 1 : $end;
        Bit_set( $bitsets[$i], int( $size / 2 ), $end );
    }
    Bit_set( $bits[0],    int( $size / 2 ) - 1, int( $size / 2 ) + 5 );
    Bit_set( $bitsets[0], int( $size / 2 ),     int( $size / 2 ) + 5 );

    # Create BitDB containers
    my $db1 = BitDB_new( $size, $num_of_bits );
    my $DB = BitDB_new( $size, $num_of_ref_bits );

    # Now put the bitsets into the containers
    for my $i ( 0 .. $num_of_bits - 1 ) {
        BitDB_put_at( $db1, $i, $bits[$i] );
    }
    for my $i ( 0 .. $num_of_ref_bits - 1 ) {
        BitDB_put_at( $DB, $i, $bitsets[$i] );
    }
    
    say "Count : $_" for BitDB_count($db1)->@*;
    use FFI::Platypus::Buffer;
    use FFI::Platypus::Memory;
    use Config;                     # to get the size of int

    my $num_threads = 4;
    my $opts        = Bit::Set::DB::SETOP_COUNT_OPTS->new(
        num_cpu_threads     => $num_threads,
        device_id           => 0,
        upd_1st_operand     => 0,
        upd_2nd_operand     => 0,
        release_1st_operand => 0,
        release_2nd_operand => 0,
        release_counts      => 0
    );
    my $nelem = BitDB_nelem($db1) * BitDB_nelem($DB);

    # Method 1: Using Perl arrays of Bit::Set
    my @cpu_set_counts;
    for my $i ( 0 .. $num_of_bits - 1 ) {
        for my $j ( 0 .. $num_of_ref_bits - 1 ) {
            my $count = Bit_inter_count( $bits[$i], $bitsets[$j] );
            push @cpu_set_counts, $count;
        }
    }

    # Method 2: Using Bit::Set::DB containers
    my $cpu_DB_counts_ptr = BitDB_inter_count_cpu( $db1, $DB, $opts );



    print "$_ " for @cpu_set_counts;
    print "\n";
    print "$_ " for $cpu_DB_counts_ptr->@*;
    print "\n";



=item Example 3: Containerized Operations in the GPU

This example continues Example 2 by performing the intersection count using the
GPU accelerated functions in the C<Bit::Set::DB> module. The code is rather
similar to the CPU version, with the major changes being the different set of
options passed. Importantly, access patterns for the results is the same as 
the CPU interface. Memory allocations to and from the device are handled by 
the C library, though the user has absolute control over what is de-allocated
and when as explained in the documentation of L<Bit|https://github.com/chrisarg/Bit>.
In particular the options argument: 

    my $opts = Bit::Set::DB::SETOP_COUNT_OPTS->new(
        num_cpu_threads     => ... ,  # number of CPU threads
        device_id           =>  ... , # GPU device ID, ignored for CPU
        upd_1st_operand     =>  ... , # if true, update the first container in the GPU
        upd_2nd_operand     =>  ... , # if true, update the second container in the GPU
        release_1st_operand =>  ... , # if true, release the first container in the GPU
        release_2nd_operand =>  ... , # if true, release the second container in the GPU
        release_counts      =>  ... , # if true, release the counts buffer in the GPU
    );

provide a way to update (replace the value of the containers) and release the 
memory used by the containers in the GPU when no longer needed. This way one 
can undertake batch operations more efficiently by preventing updating and de-
allocation of the buffers when they are no longer needed. 

For example, if the memory of the GPU can accomodate both containers and the
intermediate results, we would ue the following code that continues Example 2:

    my $gpu_opts = Bit::Set::DB::SETOP_COUNT_OPTS->new(
    num_cpu_threads     => $num_threads,
    device_id           => 0,
    upd_1st_operand     => 0,
    upd_2nd_operand     => 0,
    release_1st_operand => 1,
    release_2nd_operand => 1,
    release_counts      => 1
    );

    # Method 3: Using Bit::Set::DB containers in the GPU
    my $gpu_DB_counts_ptr = BitDB_inter_count_gpu( $db1, $DB, $gpu_opts,1 );

    my $gpu_scalar = buffer_to_scalar $gpu_DB_counts_ptr, $nelem*$Config{intsize};
    my  @gpu_DB_counts = unpack( "i[$nelem]", $gpu_scalar );
    free $gpu_DB_counts_ptr;
    print "$_ " for @gpu_DB_counts;

=item Example 4: Perl Data Language (PDL) access pattern for C<Bit::Set::DB> results

Having the result in a C array, one can avoid the overhead of mapping them to a
Perl scalar and then unpack them to an array, by wrapping them into a PDL ndarray.
The pattern for wrapping external buffers in PDL is decribed in the L<PDL::API|https://metacpan.org/dist/PDL/view/lib/PDL/API.pod#Wrapping-your-own-data-into-an-ndarray>,
and was also presented in my L<talk|https://www.slideshare.net/slideshow/the-perl-module-task-memmanager-a-module-for-managing-memory-for-foreign-applications-from-perl/274192775> for L<Perl Community Conference Winter 2024|https://blogs.perl.org/users/oodler_577/2024/11/registration-is-open---perl-community-conference-winter-2024.html>.
To use this access pattern, we will need to import various C<PDL> and C<Inline> 
packages and the PDL datatypes we will like to use. Continuing after Example 3, 
we now have: 

    use PDL::LiteF;
    use PDL::Types '$PDL_L';    # Long which is equivalent to int in 64bit systems
    use Inline with => 'PDL';
    use Inline C    => 'DATA';

and write an C<Inline> block to wrap around the buffer returned by the containerized
functions in C<Bit::Set::DB>. This inline block defines the function C<mkndarray> and
the relevant C code (reproduced below for completeness) was modified from L<PDL::API|https://metacpan.org/dist/PDL/view/lib/PDL/API.pod#Wrapping-your-own-data-into-an-ndarray>:

    __DATA__
    __C__
    #include <stdio.h>
    #include <stdlib.h>
    #include <stdint.h>

    #define IsSVValidPtr(sv)  do { \
        if (!SvOK((sv))) { \
            croak("Pointer is not defined"); \
        } \
        if (!SvIOK((sv))) { \
            croak("Pointer does not contain an integer"); \
        } \
        IV value = SvIV((sv)); \
        if (value <= 0) { \
                croak("Pointer is negative or zero"); \
        } \
    } while(0)

    #define DeclTypedPtr(type, ptr,sv) type *ptr; \
                            ptr = (type *) SvIV((sv))

    void generate_random_double_array(SV *sv, size_t num_elements) {
        IsSVValidPtr(sv);
        DeclTypedPtr(double, array, sv);
        for (size_t i = 0; i < num_elements; ++i) {
            array[i] = ((double)rand() / RAND_MAX) * 10.0 - 5.0;
        }
    }

    double sum_array_C(SV *sv, size_t length) {
        IsSVValidPtr(sv);
        double sum = 0.0;
        DeclTypedPtr(double, array, sv);
        for (size_t i = 0; i < length; i++) {
            sum += array[i];
        }
        return sum;
    }


    // Start of material from the PDL::API documentation
    void delete_mydata(pdl* pdl, int param) {
        pdl->data = 0;
    }

    typedef void (*DelMagic)(pdl *, int param);
    static void default_magic(pdl *p, int pa) { p->data = 0; }
    static pdl* pdl_wrap(void *data, int datatype, PDL_Indx dims[],
    int ndims, DelMagic delete_magic, int delparam)
    {
    pdl* p = PDL->pdlnew(); /* get the empty container */
    if (!p) return p;
    pdl_error err = PDL->setdims(p, dims, ndims);  /* set dims */
    if (err.error) { PDL->destroy(p); return NULL; }
    p->datatype = datatype;     /* and data type */
    p->data = data;             /* point it to your data */
    /* make sure the core doesn't meddle with your data */
    p->state |= PDL_DONTTOUCHDATA | PDL_ALLOCATED;
    if (delete_magic != NULL)
        PDL->add_deletedata_magic(p, delete_magic, delparam);
    else
        PDL->add_deletedata_magic(p, default_magic, 0);
    return p;
    }
    // End of material straight from the PDL::API documentation


    // modified from the PDL::API documentation
    pdl *mkndarray(SV *external_buffer, int datatype, AV *dims, size_t ndims) {
    IsSVValidPtr(external_buffer);
    size_t len = av_len(dims) + 1;
    if (ndims != len) {
        croak("Number of dimensions does not match the number of elements in dims");
    }

    pdl *p;
    PDL_Indx dimensions[ndims];
    for (int i = 0; i < len; i++) {
        SV **elem = av_fetch_simple(dims, i, 0); // perl 5.36 and above
        dimensions[i] = SvUV(*elem);
    }
    DeclTypedPtr(void, mydata, external_buffer);
    p = pdl_wrap(mydata, datatype, dimensions, ndims,
                delete_mydata, 0);
    return p;
    }

The function C<mkndarray> creates a new PDL (Perl Data Language) object from an external buffer, 
a data type (exported from the L<PDL::Typeshttps://metacpan.org/pod/PDL::Types>), a set of dimensions
(provided as a Perl array reference), and the number of dimensions. 
The actual access pattern in Perl is rather straightforward:

    my $gpu_DB_counts_ptr = BitDB_inter_count_gpu( $db1, $DB, $gpu_opts,1 );
    my $pdl = mkndarray( $gpu_DB_counts_ptr, $PDL_L, [$nelem], 1 );

    print $pdl->index($_)," " for 0 .. $nelem - 1;
    print "\n";
    undef $pdl;
    free $gpu_DB_counts_ptr;

Note that when managing memory, undefining the PDL object does not lead to the
release of the allocated buffer, which must be manually released. Note the order
of de-allocations: B<first> the PDL object, then the external buffer.
One should strongly consider using the C<defer> keyword to properly sequence
the de-allocations and avoid segmentation faults.


=item Example 5: Profiling access patterns for results

This example provides a self-contained code profiler for an intersection count
between two groups of bitsets. We will profile the performance of population
counts of the intersection of these bitsets to find the maximum popcount via

=over 5

=item Nested Perl loops to over Perl arrays of C<Bit::Set>

=item Multi-threaded container operations in the CPU using Perl arrays to find the maximum popcount

=item Container operations in the GPU using Perl arrays to find the maximum popcount

=item Multi-threaded container operations in the GPU using PDL to find the maximum popcount

=item Multi-threaded container operations in the GPU using PDL to find the maximum popcount

=back

In the Xeon E-2697v4 I used for this work, I obtained the following benchmarks by invoking the profiler as C<./profiler.pl  1024 1000 1000 4>:

    Test Description             | Time (ns)    | Searches/sec | Threads | Result | Speedup
    ---------------------------- | ------------ | ------------ | ------- | ------ | -------
    Bit::Set operations - Rep1   | 388,479,000  | 2.57         | 1       | 512    | 1.00
    Bit::Set operations - Rep2   | 389,512,000  | 2.57         | 1       | 512    | 1.00
    Bit::Set operations - Rep3   | 389,775,000  | 2.57         | 1       | 512    | 1.00
    Container - CPU              | 82,856,000   | 12.07        | 1       | 512    | 4.69
    Container - CPU              | 62,179,000   | 16.08        | 2       | 512    | 6.25
    Container - CPU              | 59,269,000   | 16.87        | 3       | 512    | 6.55
    Container - CPU              | 61,368,000   | 16.30        | 4       | 512    | 6.33
    Container - GPU              | 261,441,000  | 3.82         | GPU     | 512    | 1.49
    Container - GPU              | 62,523,000   | 15.99        | GPU     | 512    | 6.21
    Container - GPU              | 61,467,000   | 16.27        | GPU     | 512    | 6.32
    Container - CPU - PDL        | 12,559,000   | 79.62        | 1       | 512    | 30.93
    Container - CPU - PDL        | 9,313,000    | 107.38       | 2       | 512    | 41.71
    Container - CPU - PDL        | 5,441,000    | 183.79       | 3       | 512    | 71.40
    Container - CPU - PDL        | 4,457,000    | 224.37       | 4       | 512    | 87.16
    Container - GPU with PDL     | 10,763,000   | 92.91        | GPU     | 512    | 36.09
    Container - GPU with PDL     | 8,662,000    | 115.45       | GPU     | 512    | 44.85
    Container - GPU with PDL     | 8,247,000    | 121.26       | GPU     | 512    | 47.11

The table clearly illustrates the significant speed up of the containerized 
operations over the C<Bit::Set>, but also the overhead of using Perl arrays to
process the results versus the PDL data access pattern

The code for the benchmark runs as a commandline command script and is the following:

    use strict;
    use warnings;
    use Time::HiRes qw(gettimeofday tv_interval);
    use Bit::Set     qw(:all);
    use Bit::Set::DB qw(:all);
    use Carp         qw(croak);
    use FFI::Platypus::Buffer;
    use FFI::Platypus::Memory;
    use Config;    # to get the size of int
    use PDL::LiteF;
    use PDL::Types '$PDL_L';    # Long which is equivalent to int in 64bit systems
    use Inline with => 'PDL';
    use Inline C    => 'DATA';

    # Constants
    use constant MAX_THREADS => 1024;
    use constant MIN_SIZE    => 128;

    # Parse command line arguments
    my ( $size, $num_of_bits, $num_of_ref_bits, $max_threads );

    sub usage {
        my $prog = $0;
        print STDERR
    "Usage: $prog <size> <number of bitsets> <number of reference bitsets> <max threads>\n";
        print STDERR "Example: $prog 1024 1000 1000000 4\n";
        print STDERR
        "This will create 1000 bitsets size 1024, do an intersection count\n";
        print STDERR
        "against another 1000000 bitsets, and run the test for 1-4 threads.\n";
        print STDERR "Please ensure that the size is a positive integer.\n";
        exit 1;
    }

    # Simple argument parsing 
    usage() unless @ARGV == 4;

    ( $size, $num_of_bits, $num_of_ref_bits, $max_threads ) = @ARGV;

    # Validate arguments
    for my $arg ( $size, $num_of_bits, $num_of_ref_bits, $max_threads ) {
        unless ( $arg =~ /^\d+$/ && $arg > 0 ) {
            print STDERR
    "Error: size, number of bits, number of ref bits, and max threads must be positive integers.\n";
            exit 1;
        }
    }

    # Apply limits
    if ( $max_threads > MAX_THREADS ) {
        print STDERR "Warning: max threads capped to " . MAX_THREADS . "\n";
        $max_threads = MAX_THREADS;
    }

    if ( $size < MIN_SIZE ) {
        print STDERR "Warning: size increased to " . MIN_SIZE . "\n";
        $size = MIN_SIZE;
    }

    print "Starting Perl benchmarks \n";

    # Allocate the bitsets
    print "Allocating bitsets...\n";
    my @bits;
    my @bitsets;

    for my $i ( 0 .. $num_of_bits - 1 ) {
        $bits[$i] = Bit_new($size);
        Bit_set( $bits[$i], int( $size / 2 ), $size - 1 );
    }

    for my $i ( 0 .. $num_of_ref_bits - 1 ) {
        $bitsets[$i] = Bit_new($size);
        Bit_set( $bitsets[$i], int( $size / 2 ), $size - 1 );
    }

    # Set some specific patterns for testing
    Bit_set( $bits[0],    int( $size / 2 ) - 1, int( $size / 2 ) + 5 );
    Bit_set( $bitsets[0], int( $size / 2 ),     int( $size / 2 ) + 5 );

    print "Finished allocating bitsets\n";

    # Create BitDB containers
    my $db1 = BitDB_new( $size, $num_of_bits );
    my $DB = BitDB_new( $size, $num_of_ref_bits );

    for my $i ( 0 .. $num_of_bits - 1 ) {
        BitDB_put_at( $db1, $i, $bits[$i] );
    }

    for my $i ( 0 .. $num_of_ref_bits - 1 ) {
        BitDB_put_at( $DB, $i, $bitsets[$i] );
    }

    print "Finished allocating BitDB\n";

    # Benchmark functions
    sub database_match {
        my ( $bits_ref, $bitsets_ref ) = @_;

        my $max = 0;
        my @counts;
        $#counts = ( scalar(@$bits_ref) * scalar(@$bitsets_ref) ) - 1;

        for my $i ( 0 .. @$bits_ref - 1 ) {
            for my $j ( 0 .. @$bitsets_ref - 1 ) {
                my $count = Bit_inter_count( $bits_ref->[$i], $bitsets_ref->[$j] );
                $counts[ $i * @$bitsets_ref + $j ] = $count;
            }
        }

        $max = ( ( $_ > $max ) ? $_ : $max ) for (@counts);

        return $max;
    }

    sub database_match_container_cpu {
        my ( $db1, $DB, $num_threads ) = @_;

        # Create the options structure for CPU processing
        my $opts = Bit::Set::DB::SETOP_COUNT_OPTS->new(
            num_cpu_threads     => $num_threads,
            device_id           => 0,
            upd_1st_operand     => 0,
            upd_2nd_operand     => 0,
            release_1st_operand => 0,
            release_2nd_operand => 0,
            release_counts      => 0
        );
        my $nelem = BitDB_nelem($db1) * BitDB_nelem($DB);

        my $results = BitDB_inter_count_cpu( $db1, $DB, $opts ,1);
        my $scalar    = buffer_to_scalar $results, $nelem * $Config{intsize};
        my @DB_counts = unpack( "i[$nelem]", $scalar );
        free $results;

        my $max = 0;
        $max = ( ( $_ > $max ) ? $_ : $max ) for (@DB_counts);

        return $max;
    }

    sub database_match_container_cpu_pdl {
        my ( $db1, $DB, $num_threads ) = @_;

        # Create the options structure for CPU processing
        my $opts = Bit::Set::DB::SETOP_COUNT_OPTS->new(
            num_cpu_threads     => $num_threads,
            device_id           => 0,
            upd_1st_operand     => 0,
            upd_2nd_operand     => 0,
            release_1st_operand => 0,
            release_2nd_operand => 0,
            release_counts      => 0
        );
        my $nelem = BitDB_nelem($db1) * BitDB_nelem($DB);

        my $results = BitDB_inter_count_cpu( $db1, $DB, $opts, 1 );
        my $pdl = mkndarray( $results, $PDL_L, [$nelem], 1 );
        my $max = $pdl->max();

        undef $pdl;
        free $results;
        return $max;
    }

    sub database_match_container_gpu {
        my ( $db1, $DB, $opts_ref ) = @_;

        my $opts = Bit::Set::DB::SETOP_COUNT_OPTS->new(@$opts_ref);

        my $results = BitDB_inter_count_gpu( $db1, $DB, $opts, 1 );
        my $nelem = BitDB_nelem($db1) * BitDB_nelem($DB);
        my $scalar    = buffer_to_scalar $results, $nelem * $Config{intsize};
        my @DB_counts = unpack( "i[$nelem]", $scalar );

        free $results;

        my $max = 0;
        $max = ( ( $_ > $max ) ? $_ : $max ) for (@DB_counts);

        return $max;
    }

    sub database_match_container_gpu_pdl {
        my ( $db1, $DB, $opts_ref ) = @_;

        my $opts = Bit::Set::DB::SETOP_COUNT_OPTS->new(@$opts_ref);

        my $results = BitDB_inter_count_gpu( $db1, $DB, $opts,1 );
        my $nelem = BitDB_nelem($db1) * BitDB_nelem($DB);
        my $pdl = mkndarray( $results, $PDL_L, [$nelem], 1 );
        my $max = $pdl->max();
        undef $pdl;
        free $results;
        return $max;
    }

    sub summarize_results {
        my ( $test, $time_elapsed, $num_of_threads, $result, $speedup ) = @_;

        my $searches_per_sec = 1_000_000_000 / $time_elapsed;
        my $thread_info =
        $num_of_threads > 0 ? sprintf( "%3d", $num_of_threads ) : "GPU";

        printf "Total time for %-35s: %15.0f ns\t", $test, $time_elapsed;
        printf "Searches per second : %0.2f\t",     $searches_per_sec;
        printf "Number of threads: %s \t",          $thread_info;
        printf "Result: %d\t",                      $result;
        printf "Speedup factor: %.2f\n",            $speedup;
    }

    # Storage for timings and results
    my @timings;
    my @results;

    print "Running benchmarks...\n";

    # Warm up the processor
    my $max = database_match( \@bits, \@bitsets );

    # Single-threaded runs (3 repetitions)
    for my $rep ( 1 .. 3 ) {
        my $t0 = [gettimeofday];
        $max = database_match( \@bits, \@bitsets );
        my $t1         = [gettimeofday];
        my $total_time = tv_interval( $t0, $t1 );

        push @timings, $total_time * 1_000_000_000;    # Convert to nanoseconds
        push @results, $max;
    }

    print "Finished single-threaded match\n";

    # We'll simulate the container-based operations instead
    print "Multi-threaded container operations in the CPU ...\n";

    # Simulate container CPU operations for different thread counts
    for my $threads ( 1 .. $max_threads ) {
        my $t0 = [gettimeofday];

        # In a real implementation, this would use the actual container functions
        $max = database_match_container_cpu( $db1, $DB, $threads );
        my $t1         = [gettimeofday];
        my $total_time = tv_interval( $t0, $t1 );

        push @timings, $total_time * 1_000_000_000;
        push @results, $max;
    }

    print "Finished multi-threaded match in the CPU\n";

    # Simulate GPU operations
    print "GPU container operations...\n";

    my @gpu_configs = (
        device_id           => 0,
        upd_1st_operand     => 1,
        upd_2nd_operand     => 0,
        release_1st_operand => 0,
        release_2nd_operand => 0,
        release_counts      => 0
    );

    for my $rep ( 1 .. 3 ) {
        my $t0 = [gettimeofday];
        $max = database_match_container_gpu( $db1, $DB, \@gpu_configs );
        my $t1         = [gettimeofday];
        my $total_time = tv_interval( $t0, $t1 );

        push @timings, $total_time * 1_000_000_000;
        push @results, $max;
    }
    print "Finished GPU container operations\n";

    # do one more run to release the GPU resources
    my @gpu_configs_purge = (
        device_id           => 0,
        upd_1st_operand     => 1,
        upd_2nd_operand     => 1,
        release_1st_operand => 1,
        release_2nd_operand => 1,
        release_counts      => 1
    );
    $max = database_match_container_gpu( $db1, $DB, \@gpu_configs_purge );

    print "CPU container operations with PDL memory access ...\n";
    for my $threads ( 1 .. $max_threads ) {
        my $t0 = [gettimeofday];
        $max = database_match_container_cpu_pdl( $db1, $DB, $threads );
        my $t1         = [gettimeofday];
        my $total_time = tv_interval( $t0, $t1 );

        push @timings, $total_time * 1_000_000_000;
        push @results, $max;
    }
    print "Finished CPU container operations with PDL memory access\n";

    print "GPU container operations with PDL memory access ...\n";
    for my $rep ( 1 .. 3 ) {
        my $t0 = [gettimeofday];
        $max = database_match_container_gpu_pdl( $db1, $DB, \@gpu_configs );
        my $t1         = [gettimeofday];
        my $total_time = tv_interval( $t0, $t1 );

        push @timings, $total_time * 1_000_000_000;
        push @results, $max;
    }
    print "Finished GPU container operations with PDL memory access\n";

    # Print results
    print "\nResults:\n";

    # Single-threaded results
    for my $rep ( 1 .. 3 ) {
        my $idx     = $rep - 1;
        my $speedup = $idx == 0 ? 1.0 : $timings[0] / $timings[$idx];
        summarize_results( "Bit::Set operations - Rep$rep",
            $timings[$idx], 1, $results[$idx], $speedup );
    }

    # Multi-threaded results
    for my $threads ( 1 .. $max_threads ) {
        my $idx     = 2 + $threads;
        my $speedup = $timings[0] / $timings[$idx];
        summarize_results( "Container - CPU",
            $timings[$idx], $threads, $results[$idx], $speedup );
    }

    # GPU results
    for my $gpu_run ( 1 .. 3 ) {
        my $idx     = 2 + $max_threads + $gpu_run;
        my $speedup = $timings[0] / $timings[$idx];
        summarize_results( "Container - GPU",
            $timings[$idx], -1, $results[$idx], $speedup );
    }

    for my $threads ( 1 .. $max_threads ) {
        my $idx     = 5 + $max_threads + $threads;
        my $speedup = $timings[0] / $timings[$idx];
        summarize_results( "Container - CPU - PDL",
            $timings[$idx], $threads, $results[$idx], $speedup );
    }

    for my $gpu_run ( 1 .. 3 ) {
        my $idx     = 5 + 2*$max_threads + $gpu_run;
        my $speedup = $timings[0] / $timings[$idx];
        summarize_results( "Container - GPU with PDL",
            $timings[$idx], -1, $results[$idx], $speedup );
    }


    # Helper function
    sub min {
        my ( $a, $b ) = @_;
        return $a < $b ? $a : $b;
    }

    # Cleanup
    print "\nCleaning up...\n";

    for my $bit (@bits) {
        Bit_free( \$bit );
    }

    for my $bitset (@bitsets) {
        Bit_free( \$bitset );
    }

    BitDB_free( \$db1 );
    BitDB_free( \$DB );

    print "Benchmark completed!\n";


    __DATA__
    __C__
    #include <stdio.h>
    #include <stdlib.h>
    #include <stdint.h>

    #define IsSVValidPtr(sv)  do { \
        if (!SvOK((sv))) { \
            croak("Pointer is not defined"); \
        } \
        if (!SvIOK((sv))) { \
            croak("Pointer does not contain an integer"); \
        } \
        IV value = SvIV((sv)); \
        if (value <= 0) { \
                croak("Pointer is negative or zero"); \
        } \
    } while(0)

    #define DeclTypedPtr(type, ptr,sv) type *ptr; \
                            ptr = (type *) SvIV((sv))

    void generate_random_double_array(SV *sv, size_t num_elements) {
        IsSVValidPtr(sv);
        DeclTypedPtr(double, array, sv);
        for (size_t i = 0; i < num_elements; ++i) {
            array[i] = ((double)rand() / RAND_MAX) * 10.0 - 5.0;
        }
    }

    double sum_array_C(SV *sv, size_t length) {
        IsSVValidPtr(sv);
        double sum = 0.0;
        DeclTypedPtr(double, array, sv);
        for (size_t i = 0; i < length; i++) {
            sum += array[i];
        }
        return sum;
    }


    // Start of material from the PDL::API documentation
    void delete_mydata(pdl* pdl, int param) {
        pdl->data = 0;
    }

    typedef void (*DelMagic)(pdl *, int param);
    static void default_magic(pdl *p, int pa) { p->data = 0; }
    static pdl* pdl_wrap(void *data, int datatype, PDL_Indx dims[],
    int ndims, DelMagic delete_magic, int delparam)
    {
    pdl* p = PDL->pdlnew(); /* get the empty container */
    if (!p) return p;
    pdl_error err = PDL->setdims(p, dims, ndims);  /* set dims */
    if (err.error) { PDL->destroy(p); return NULL; }
    p->datatype = datatype;     /* and data type */
    p->data = data;             /* point it to your data */
    /* make sure the core doesn't meddle with your data */
    p->state |= PDL_DONTTOUCHDATA | PDL_ALLOCATED;
    if (delete_magic != NULL)
        PDL->add_deletedata_magic(p, delete_magic, delparam);
    else
        PDL->add_deletedata_magic(p, default_magic, 0);
    return p;
    }
    // End of material straight from the PDL::API documentation


    // modified from the PDL::API documentation
    pdl *mkndarray(SV *external_buffer, int datatype, AV *dims, size_t ndims) {
    IsSVValidPtr(external_buffer);
    size_t len = av_len(dims) + 1;
    if (ndims != len) {
        croak("Number of dimensions does not match the number of elements in dims");
    }

    pdl *p;
    PDL_Indx dimensions[ndims];
    for (int i = 0; i < len; i++) {
        SV **elem = av_fetch_simple(dims, i, 0); // perl 5.36 and above
        dimensions[i] = SvUV(*elem);
    }
    DeclTypedPtr(void, mydata, external_buffer);
    p = pdl_wrap(mydata, datatype, dimensions, ndims,
                delete_mydata, 0);
    return p;
    }

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

=item L<Bit::Set|https://metacpan.org/pod/Bit::Set>

C<Bit::Set> is a Perl module that provides a high-level I<procedural> interface 
for working with bitsets. It is built on top of the Bit library and offers a 
more user-friendly Perl API for common bitset operations. 
It is the parent module of C<Bit::Set::DB> and provides further details about 
the vibecoding of the C<Bit::Set::DB> module.

=item L<Bit::Set::OO|https://metacpan.org/pod/Bit::Set::OO>

Object Oriented interface to the Bit::Set module.

=item L<Bit::Set::DB::OO|https://metacpan.org/pod/Bit::Set::DB::OO>

Object Oriented interface to the Bit::Set::DB module.

=item L<Bit::Vector|https://metacpan.org/pod/Bit::Vector>

Efficient bit vector, set of integers and "big int" math library

=item L<Lucy::Object::BitVector|https://metacpan.org/dist/Lucy/view/lib/Lucy/Object/BitVector.pod>

Bit vector implementation used in the L<Lucy|https://metacpan.org/pod/Lucy> search engine library.

=back

=head1 TO DO

=over 4

=item * Add more examples.

=item * Add more tests.

=item* Switch to XS for better performance.

=back

=head1 AUTHOR

Christos Argyropoulos and Joe Schaefer after v0.11.
Christos Argyropoulos with asistance from Github Copilot (Claude Sonnet 4) up to v0.10.

=head1 COPYRIGHT AND LICENSE

This software up to and including v0.10 is copyright (c) 2025 Christos Argyropoulos.
For versions after v0.10, the distribution as a whole is copyright (c) 2025 Joe Schaefer and Christos Argyropoulos.

This software is released under the L<MIT license|https://mit-license.org/>.

=cut
