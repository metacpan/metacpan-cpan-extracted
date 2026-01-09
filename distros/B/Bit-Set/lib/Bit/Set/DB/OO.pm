#!/home/chrisarg/perl5/perlbrew/perls/current/bin/perl
package Bit::Set::DB::OO;
$Bit::Set::DB::OO::VERSION = '0.12';
use strict;
use warnings;

XSLoader::load('Bit::Set::DB');
# Load the XS-based SETOP_COUNT_OPTS class
use Bit::Set::DB::SETOP_COUNT_OPTS;

1;

__END__



=head1 NAME

Bit::Set::DB::OO - Perl Object Oriented (OO) interface for bitset containers 
from the C<Bit> C library

=head1 VERSION

version 0.12

=head1 SYNOPSIS

  use Bit::Set::DB::OO;         ## OO interface to BitDB C library
  use Bit::Set::DB qw(:all);    ## Procedural interface to BitDB C library 
                                ## (but do you need this if you use OO?)

  # Create a new bitset database
  my $bitdb = Bit::Set::DB->new(1024, 10); # 10 bitsets of length 1024 bits each

  # Get a bitset from the database
  my $bitset = $bitdb->get_from(0); # Get the first bitset

  # Perform set operations
  my $other_bitset = $bitdb->get_from(1); # Get the second bitset
  my $union_bitset = $bitset->union($other_bitset);

  # Count set bits in the union
  my $count = $union_bitset->count();


=head1 DESCRIPTION

This module provides an OO Perl interface to the C library C<Bit>,
for creating and manipulating containers of bitsets (BitDB), leveraging
multithreadedand hardware accelerated (e.g. GPU) versions of container 
operations e.g. forming the population count of the intersection of two 
containers of bitsets.

This is a pure OO interface using Perl's XS mechanism to interface with the
C<Bit> library.



GPU offloading is disabled if you set up the C<NOGPU> environment variable.

=head1 METHODS

The methods provided by this module correspond to the functions provided
by the procedural interface in L<Bit::Set::DB|https://metacpan.org/pod/Bit::Set::DB>.
The method names correspond to the function names without the C<BitDB_> prefix.
Note that the methods are created in the Bit::Set::DB namespace.

=head2 Creation

=over 4

=item B<Bit::Set::DB-E<gt>new(length, num_of_bitsets)>

Creates a new bitset container for C<num_of_bitsets> bitsets, each of C<length>.

=item B<Bit::Set::DB-E<gt>load(length, num_of_bitsets, buffer address - numeric)>

Creates a new bitset container for C<num_of_bitsets> bitsets, each of C<length>, 
from an external buffer. The buffer address should point to a memory region 
large enough to hold all bitsets.

=back

=head2 Properties

=over 4

=item B<$container-E<gt>length(set)>

Returns the length of bitsets in the container.

=item B<$container-E<gt>nelem()>

Returns the number of bitsets in the container.

=item B<$container-E<gt>count_at(index)>

Returns the population count of the bitset at the given C<index>.

=item B<$container-E<gt>count()>

Returns a pointer to an array of population counts for all bitsets 
in the container.

=back

=head2 Manipulation

=over 4

=item B<$container-E<gt>get_from(index)>

Returns a bitset from the container at the given C<index>.

=item B<$container-E<gt>put_at(index, bitset)>

Puts a C<bitset> into the container at the given C<index>.

=item B<$container-E<gt>extract_from(index, buffer)>

Extracts a bitset from the container at C<index> into a C<buffer>.

=item B<$container-E<gt>replace_at(index, buffer)>

Replaces a bitset in the container at C<index> with the contents of a C<buffer>.

=item B<$container-E<gt>clear()>

Clears all bitsets in the container.

=item B<$container-E<gt>clear_at(index)>

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

Perform the respective set operation count on the CPU:

=over 5

=item B<$container-E<gt>inter_count_cpu(container2, opts,...)>

=item B<$container-E<gt>union_count_cpu(container2, opts,...)>

=item B<$container-E<gt>diff_count_cpu(container2, opts,...)>

=item B<$container-E<gt>minus_count_cpu(container2, opts,...)>

=back

Perform the respective set operation count on the GPU:

=over 5

=item B<$container-E<gt>inter_count_gpu(container2, opts,...)>

=item B<$container-E<gt>union_count_gpu(container2, opts,...)>

=item B<$container-E<gt>diff_count_gpu(container2, opts,...)>   

=item B<$container-E<gt>minus_count_gpu(container2, opts,...)>

=back


The optional C<...> argument is used to determine the type of the returned counts buffer:

=over 6

=item If omitted,undef or zero the function returns a reference to an array of integers containing the counts.

=item If the optional parameter argument value is set to the integer 1, the function will return a pointer to a buffer containing the counts as an array of integers. 

This pointer can be used with the C<Task::MemManager> module to provide a memory leak-free way to manage its lifetime.

=over 5

=item B<$container-E<gt>inter_count_store_cpu(container2, buffer, opts)>

=item B<$container-E<gt>union_count_store_cpu(container2, buffer, opts)>

=item B<$container-E<gt>diff_count_store_cpu(container2, buffer, opts)>

=item B<$container-E<gt>minus_count_store_cpu(container2, buffer, opts)>

=back

Perform the respective set operation count on the GPU and store results in C<buffer>:

=over 5

=item B<$container-E<gt>inter_count_store_gpu(container2, buffer, opts)>

=item B<$container-E<gt>union_count_store_gpu(container2, buffer, opts)>

=item B<$container-E<gt>diff_count_store_gpu(container2, buffer, opts)>

=item B<$container-E<gt>minus_count_store_gpu(container2, buffer, opts)>

=back


=head1 EXAMPLES

Examples of the use of the C<Bit::Set::DB::OO> module that illustrates the use
of the OO interface for bitset containers. The parent module C<Bit::Set::DB>
provides further procedural examples of the use of bitset containers.

=over 4

=item Example 1: Creating and initializing containers

In this example, we will create two Perl arrays of C<Bit::Set> and then load
them to C<Bit::Set::DB> containers using the OO interface.



    use strict;
    use warnings;
    use Bit::Set::OO;
    use Bit::Set::DB::OO;

    my $size            = 1024;
    my $num_of_bits     = 3;
    my $num_of_ref_bits = 5;

    my @bits;
    my @bitsets;

    # Initializing and setting the values of the bitsets
    for my $i ( 0 .. $num_of_bits - 1 ) {
        $bits[$i] = Bit::Set->new($size);
        my $end = int( $size / 2 ) + $i;
        $end = ( $end > $size - 1 ) ? $size - 1 : $end;
         $bits[$i]->set( int( $size / 2 ), $end );
    }
    for my $i ( 0 .. $num_of_ref_bits - 1 ) {
        $bitsets[$i] = Bit::Set->new($size);
        my $end = int( $size / 2 ) + $i;
        $end = ( $end > $size - 1 ) ? $size - 1 : $end;
        $bitsets[$i]->set( int( $size / 2 ), $end );
    }
    $bits[0]->set(    int( $size / 2 ) - 1, int( $size / 2 ) + 5 );
    $bitsets[0]->set( int( $size / 2 ),     int( $size / 2 ) + 5 );

    # Create BitDB containers
    my $db1 = Bit::Set::DB->new( $size, $num_of_bits );
    my $DB = Bit::Set::DB->new( $size, $num_of_ref_bits );

    # Now put the bitsets into the containers
    for my $i ( 0 .. $num_of_bits - 1 ) {
        $db1->put_at( $i, $bits[$i] );
    }
    for my $i ( 0 .. $num_of_ref_bits - 1 ) {
        $DB->put_at( $i, $bitsets[$i] );
    }
    
    say $_ for do{my $x = $db1->count; $x->@*};

=item Example 2: Obtaining the counts of bitset operations using containers and OO

This example continues Example 1 by performing the intersection count in two
different ways: 1) iterating over the Perl arrays of bitsets and 2) using the
BitDB containers directly. A major benefit of these containerized operations
is that they can leverage multi-threading in the CPU and hardware acceleration
in GPUs (and TPUs in the near future).

    use Test::More;
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
    my $nelem = $db1->nelem() * $DB->nelem();

    # Method 1: Using Perl arrays of Bit::Set
    my @cpu_set_counts;
    for my $i ( 0 .. $num_of_bits - 1 ) {
        for my $j ( 0 .. $num_of_ref_bits - 1 ) {
            my $count = $bits[$i]->inter_count( $bitsets[$j] );
            push @cpu_set_counts, $count;
        }
    }

    # Method 2: Using Bit::Set::DB containers
    my $cpu_DB_counts_ptr = $db1->inter_count_cpu( $DB, $opts );
    my $test_result = 1;
    for my $k ( 0 .. $nelem - 1 ) {
        if ( $cpu_DB_counts_ptr->[$k] != $cpu_set_counts[$k] ) {
            $test_result = 0;
            last;
        }
    }
    ok( $test_result, "BitDB CPU intersection counts match Bit::Set counts" );

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

=item L<Bit::Set::OO|https://metacpan.org/pod/Bit::Set::OO>

Object Oriented interface to the Bit::Set module.

=item L<Bit::Set::DB|https://metacpan.org/pod/Bit::Set::DB>

Procedural interface to the containerized operations of the Bit library.

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

For versions after v0.10, the distribution as a whole is copyright (c) 2025 Joe Schaefer and Christos Argyropoulos.
This software up to and including v0.10 is copyright (c) 2025 Christos Argyropoulos.

This software is released under the L<MIT license|https://mit-license.org/>.

=cut
