#!/home/chrisarg/perl5/perlbrew/perls/current/bin/perl
package Bit::Set::DB::OO;
$Bit::Set::DB::OO::VERSION = '0.09';
use strict;
use warnings;

use Alien::Bit;
use Bit::Set::DB qw( :all );
use Bit::Set::OO;
use FFI::Platypus;

###############################################################################
# Code for the OO interface
# The functions in the OO interface are named identically to the procedural one
# sans the prefix "BitDB_"

# Creation and Destruction

package Bit::Set::DB {
$Bit::Set::DB::VERSION = '0.09';
sub new {
        my ( $class, $length, $num_of_bitsets ) = @_;
        my $self = BitDB_new( $length, $num_of_bitsets );
        return bless \$self, $class;
    }

    sub DESTROY {
        my ($self) = @_;
        BitDB_free($self);
    }

    sub load {
        my ( $class, $length, $num_of_bitsets, $buffer ) = @_;
        my $self = BitDB_load( $length, $num_of_bitsets, $buffer );
        return bless \$self, $class;
    }

    # Properties

    sub length {
        my ($self) = @_;
        return BitDB_length($$self);
    }

    sub nelem {
        my ($self) = @_;
        return BitDB_nelem($$self);
    }

    sub count_at {
        my ( $self, $index ) = @_;
        return BitDB_count_at( $$self, $index );
    }

    sub count {
        my ($self) = @_;
        return BitDB_count($$self);
    }

    # Manipulation
    sub get_from {
        my ( $self, $index ) = @_;
        my $bit = BitDB_get_from( $$self, $index );
        return bless( \$bit, 'Bit::Set' );
    }

    sub put_at {
        my ( $self, $index, $bitset ) = @_;
        BitDB_put_at( $$self, $index, $$bitset );
    }

    sub extract_from {
        my ( $self, $index, $buffer ) = @_;
        return BitDB_extract_from( $$self, $index, $buffer );
    }

    sub replace_at {
        my ( $self, $index, $buffer ) = @_;
        BitDB_replace_at( $$self, $index, $buffer );
    }

    sub clear {
        my ($self) = @_;
        BitDB_clear($$self);
    }

    sub clear_at {
        my ( $self, $index ) = @_;
        BitDB_clear_at( $$self, $index );
    }

    # SETOP Count Store CPU

    sub inter_count_store_cpu {
        my ( $self, $other, $buffer, $opts ) = @_;
        return BitDB_inter_count_store_cpu( $$self, $$other, $buffer, $opts );
    }

    sub union_count_store_cpu {
        my ( $self, $other, $buffer, $opts ) = @_;
        return BitDB_union_count_store_cpu( $$self, $$other, $buffer, $opts );
    }

    sub diff_count_store_cpu {
        my ( $self, $other, $buffer, $opts ) = @_;
        return BitDB_diff_count_store_cpu( $$self, $$other, $buffer, $opts );
    }

    sub minus_count_store_cpu {
        my ( $self, $other, $buffer, $opts ) = @_;
        return BitDB_minus_count_store_cpu( $$self, $$other, $buffer, $opts );
    }

    # SETOP Count Store GPU

    sub inter_count_store_gpu {
        my ( $self, $other, $buffer, $opts ) = @_;
        return BitDB_inter_count_store_gpu( $$self, $$other, $buffer, $opts );
    }

    sub union_count_store_gpu {
        my ( $self, $other, $buffer, $opts ) = @_;
        return BitDB_union_count_store_gpu( $$self, $$other, $buffer, $opts );
    }

    sub diff_count_store_gpu {
        my ( $self, $other, $buffer, $opts ) = @_;
        return BitDB_diff_count_store_gpu( $$self, $$other, $buffer, $opts );
    }

    sub minus_count_store_gpu {
        my ( $self, $other, $buffer, $opts ) = @_;
        return BitDB_minus_count_store_gpu( $$self, $$other, $buffer, $opts );
    }

    # SETOP Count CPU

    sub inter_count_cpu {
        my ( $self, $other, $opts ) = @_;
        return BitDB_inter_count_cpu( $$self, $$other, $opts );
    }

    sub union_count_cpu {
        my ( $self, $other, $opts ) = @_;
        return BitDB_union_count_cpu( $$self, $$other, $opts );
    }

    sub diff_count_cpu {
        my ( $self, $other, $opts ) = @_;
        return BitDB_diff_count_cpu( $$self, $$other, $opts );
    }

    sub minus_count_cpu {
        my ( $self, $other, $opts ) = @_;
        return BitDB_minus_count_cpu( $$self, $$other, $opts );
    }

    # SETOP Count GPU

    sub inter_count_gpu {
        my ( $self, $other, $opts ) = @_;
        return BitDB_inter_count_gpu( $$self, $$other, $opts );
    }

    sub union_count_gpu {
        my ( $self, $other, $opts ) = @_;
        return BitDB_union_count_gpu( $$self, $$other, $opts );
    }

    sub diff_count_gpu {
        my ( $self, $other, $opts ) = @_;
        return BitDB_diff_count_gpu( $$self, $$other, $opts );
    }

    sub minus_count_gpu {
        my ( $self, $other, $opts ) = @_;
        return BitDB_minus_count_gpu( $$self, $$other, $opts );
    }
}

1;


__END__

=head1 NAME

Bit::Set::DB::OO - Perl Object Oriented (OO) interface for bitset containers 
from the C<Bit> C library

=head1 VERSION

version 0.09

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

As currently implemented the OO interfaces are currently layered on top of the 
procedural API, and thus incur some overhead compared to direct calls to the 
procedural API.



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

=item B<$container-E<gt>inter_count_cpu(container2, opts)>

=item B<$container-E<gt>union_count_cpu(container2, opts)>

=item B<$container-E<gt>diff_count_cpu(container2, opts)>

=item B<$container-E<gt>minus_count_cpu(container2, opts)>

=back

Perform the respective set operation count on the GPU:

=over 5

=item B<$container-E<gt>inter_count_gpu(container2, opts)>

=item B<$container-E<gt>union_count_gpu(container2, opts)>

=item B<$container-E<gt>diff_count_gpu(container2, opts)>   

=item B<$container-E<gt>minus_count_gpu(container2, opts)>

=back

Perform the respective set operation count on the CPU and store results in C<buffer>:

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
    my $db2 = Bit::Set::DB->new( $size, $num_of_ref_bits );

    # Now put the bitsets into the containers
    for my $i ( 0 .. $num_of_bits - 1 ) {
        $db1->put_at( $i, $bits[$i] );
    }
    for my $i ( 0 .. $num_of_ref_bits - 1 ) {
        $db2->put_at( $i, $bitsets[$i] );
    }

=item Example 2: Obtaining the counts of bitset operations using containers and OO

This example continues Example 1 by performing the intersection count in two
different ways: 1) iterating over the Perl arrays of bitsets and 2) using the
BitDB containers directly. A major benefit of these containerized operations
is that they can leverage multi-threading in the CPU and hardware acceleration
in GPUs (and TPUs in the near future).
When we use the interface over containers, we will need to interface the integer
array returned by the C<Bit::Set::DB> interface function to Perl arrays.
This is one possible way of doing so using the C<FFI::Platypus::Buffer> and
C<FFI::Platypus::Buffer> modules. 

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
    my $nelem = $db1->nelem() * $db2->nelem();

    # Method 1: Using Perl arrays of Bit::Set
    my @cpu_set_counts;
    for my $i ( 0 .. $num_of_bits - 1 ) {
        for my $j ( 0 .. $num_of_ref_bits - 1 ) {
            my $count = $bits[$i]->inter_count( $bitsets[$j] );
            push @cpu_set_counts, $count;
        }
    }

    # Method 2: Using Bit::Set::DB containers
    my $cpu_DB_counts_ptr = $db1->inter_count_cpu( $db2, $opts );

    my $scalar = buffer_to_scalar $cpu_DB_counts_ptr, $nelem*$Config{intsize};
    my  @cpu_DB_counts = unpack( "i[$nelem]", $scalar );
    free $cpu_DB_counts_ptr;
    my $test_result = 1;
    for my $k ( 0 .. $nelem - 1 ) {
        if ( $cpu_DB_counts[$k] != $cpu_set_counts[$k] ) {
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


=back

=head1 AUTHOR

Christos Argyropoulos.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Christos Argyropoulos.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
