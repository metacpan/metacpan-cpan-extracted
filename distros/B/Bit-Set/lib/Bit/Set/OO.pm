#!/home/chrisarg/perl5/perlbrew/perls/current/bin/perl
package Bit::Set::OO;
$Bit::Set::OO::VERSION = '0.10';
use strict;
use warnings;

use Alien::Bit;
use Bit::Set qw( :all );
use FFI::Platypus;

###############################################################################
# Code for the OO interface
# The functions in the OO interface are named identically to the procedural
# one  sans the brefix "Bit_"

use Scalar::Util qw(blessed);

package Bit::Set {
$Bit::Set::VERSION = '0.10';
    # Creation and Destruction
    sub new {
        my ( $class, $length ) = @_;
        my $set = Bit_new($length);
        return bless( \$set, $class );
    }

    sub DESTROY {
        my ($self) = @_;
        Bit_free($self);
    }

    sub load {
        my ( $class, $length, $buffer ) = @_;
        my $set = Bit_load( $length, $buffer );
        return bless( \$set, $class );
    }

    sub extract {
        my ( $self, $buffer ) = @_;
        return Bit_extract( $$self, $buffer );
    }

    # Properties
    sub buffer_size {
        my ( $class, $length ) = @_;
        return Bit_buffer_size($length);
    }

    sub length {
        my ($self) = @_;
        return Bit_length($$self);
    }

    sub count {
        my ($self) = @_;
        return Bit_count($$self);
    }

    # Manipulation
    sub aset {
        my ( $self, $indices, $n ) = @_;
        Bit_aset( $$self, $indices, $n );
    }

    sub bset {
        my ( $self, $index ) = @_;
        Bit_bset( $$self, $index );
    }

    sub aclear {
        my ( $self, $indices, $n ) = @_;
        Bit_aclear( $$self, $indices, $n );
    }

    sub bclear {
        my ( $self, $index ) = @_;
        Bit_bclear( $$self, $index );
    }

    sub clear {
        my ( $self, $lo, $hi ) = @_;
        Bit_clear( $$self, $lo, $hi );
    }

    sub get {
        my ( $self, $index ) = @_;
        return Bit_get( $$self, $index );
    }

    sub not {
        my ( $self, $lo, $hi ) = @_;
        Bit_not( $$self, $lo, $hi );
    }

    sub put {
        my ( $self, $n, $val ) = @_;
        return Bit_put( $$self, $n, $val );
    }

    sub set {
        my ( $self, $lo, $hi ) = @_;
        Bit_set( $$self, $lo, $hi );
    }

    # Comparisons

    sub eq {
        my ( $self, $other ) = @_;
        return Bit_eq( $$self, $$other );
    }

    sub leq {
        my ( $self, $other ) = @_;
        return Bit_leq( $$self, $$other );
    }

    sub lt {
        my ( $self, $other ) = @_;
        return Bit_lt( $$self, $$other );
    }

    # Set Operations

    sub diff {
        my ( $self, $other ) = @_;
        my $new_set = Bit_diff( $$self, $$other );
        return bless( \$new_set, "Bit::Set" );
    }

    sub inter {
        my ( $self, $other ) = @_;
        my $new_set = Bit_inter( $$self, $$other );
        return bless( \$new_set, "Bit::Set" );
    }

    sub minus {
        my ( $self, $other ) = @_;
        my $new_set = Bit_minus( $$self, $$other );
        return bless( \$new_set, "Bit::Set" );
    }

    sub union {
        my ( $self, $other ) = @_;
        my $new_set = Bit_union( $$self, $$other );
        return bless( \$new_set, "Bit::Set" );
    }

    # Set Operation Counts

    sub diff_count {
        my ( $self, $other ) = @_;
        return Bit_diff_count( $$self, $$other );
    }

    sub inter_count {
        my ( $self, $other ) = @_;
        return Bit_inter_count( $$self, $$other );
    }

    sub minus_count {
        my ( $self, $other ) = @_;
        return Bit_minus_count( $$self, $$other );
    }

    sub union_count {
        my ( $self, $other ) = @_;
        return Bit_union_count( $$self, $$other );
    }
}


1;

__END__

=head1 NAME

Bit::Set::OO - Perl Object Oriented (OO) interface to the 'bit' C library

=head1 VERSION

version 0.10

=head1 SYNOPSIS

  use Bit::Set::OO;         ## OO interface to Bit C library
  use Bit::Set qw(:all);    ## Procedural interface to Bit C library
                            ## (but do you need this if you use OO?)

  # Create a new bitset
  my $set = Bit::Set::OO->new(1024);

  # Set some bits
  $set->bset(0);
  $set->bset(42);

  # Get population count
  my $count = $set->count();

  # Free the bitset
  undef $set;

=head1 DESCRIPTION

This module provides an OO Perl interface to the C library L<Bit|https://github.com/chrisarg/Bit>, 
for creating and manipulating bitsets. The interface mirrors the procedural
 interface provided by L<Bit::Set|https://metacpan.org/pod/Bit::Set>, 
 with methods corresponding to the functions in that module.

As currently implemented the OO interfaces are currently layered on top of the 
procedural API, and thus incur some overhead compared to direct calls to the 
procedural API. 

=head1 Methods

The methods in the Bit::Set::OO module are grouped into several categories for 
clarity, as described below. The method names correspond to the function names 
in the procedural interface without the C<Bit_> prefix. Note that the methods
are created in the Bit::Set namespace.

=head2 Creation

=over 4

=item B<Bit::Set-E<gt>new(length)>

Creates a new bitset with the specified capacity (=length) in bits. The object 
is of type Bit::Set (not Bit::Set::OO).


=item B<Bit::Set-E<gt>load(length, buffer)>

Loads an externally allocated bitset into a new Bit_T structure in C and returns
it as a Perl object of type Bit::Set.

=item B<$bitset-E<gt>extract(buffer)>

Extracts the bitset from a Bit_T into an externally allocated buffer.
Look at EXAMPLES for usage of the load and extract functions using C<FFI::Platypus>.

=back

=head2 Properties

=over 4

=item B<Bit::Set-E<gt>buffer_size(length)>

Returns the number of bytes needed to store a bitset of given length.

=item B<$bitset-E<gt>length()>
Returns the length (capacity) of the bitset in bits.

=item B<$bitset-E<gt>count()>

Returns the population count (number of set bits) of the bitset.

=back

=head2 Manipulation

=over 4

=item B<$bitset-E<gt>aset(indices, n)>

Sets an array of bits specified by indices.

=item B<$bitset-E<gt>bset(index)>

Sets a single bit at the specified index to 1.

=item B<$bitset-E<gt>aclear(indices, n)>

Clears an array of bits specified by indices.

=item B<$bitset-E<gt>bclear(index)>

Clears a single bit at the specified index to 0.

=item B<$bitset-E<gt>clear(lo, hi)>

Clears a range of bits from lo to hi (inclusive).

=item B<$bitset-E<gt>get(index)>

Returns the value of the bit at the specified index.

=item B<$bitset-E<gt>not(lo, hi)>

Inverts a range of bits from lo to hi (inclusive).

=item B<$bitset-E<gt>put(n, val)>

Sets the nth bit to val and returns the previous value.

=item B<$bitset-E<gt>set(lo, hi)>

Sets a range of bits from lo to hi (inclusive) to 1.

=back

=head2 Comparisons

=over 4

=item B<$bitset-E<gt>eq(other)>

Returns 1 if the bitset other is equal to this bitset, 0 otherwise.

=item B<$bitset-E<gt>leq(other)>

Returns 1 if this bitset is a subset of or equal to other, 0 otherwise.

=item B<$bitset-E<gt>lt(other)>

Returns 1 if this bitset is a proper subset of other, 0 otherwise.

=back

=head2 Set Operations

=over 4

=item B<$bitset-E<gt>diff(other)>

Returns a new bitset containing the difference of this bitset and other.

=item B<$bitset-E<gt>inter(other)>

Returns a new bitset containing the intersection of this bitset and other
.

=item B<$bitset-E<gt>minus(other)>

Returns a new bitset containing the symmetric difference of this bitset and other.

=item B<$bitset-E<gt>union(other)>

Returns a new bitset containing the union of this bitset and other.

=back

=head2 Set Operation Counts

=over 4

=item B<$bitset-E<gt>diff_count(other)>

Returns the population count of the difference of this bitset and other without 
creating a new bitset.

=item B<$bitset-E<gt>inter_count(other)>

Returns the population count of the intersection of this bitset and other without 
creating a new bitset.

=item B<$bitset-E<gt>minus_count(other)>

Returns the population count of the symmetric difference of this bitset and other 
without creating a new bitset.

=item B<$bitset-E<gt>union_count(other)>

Returns the population count of the union of this bitset and other without 
creating a new bitset.

=back


=head1 EXAMPLES

Examples of the use of the C<Bit::Set::OO> module. These examples are the OO 
"traslations" of examples in the C<Bit::Set> module.

=over 4

=item Example 1: Creating and using a bitset

Simple example in which we create, set and test for setting of individual 
bits into a bitset.

  use Bit::Set::OO;    ## OO interface to Bit C library

  my $bitset = Bit::Set->new(64);
  $bitset->set(1);
  $bitset->set(3);
  $bitset->set(5);

  print "Bit 1 is ", $bitset->get(1) ? "set" : "not set", "\n";
  print "Bit 2 is ", $bitset->get(2) ? "set" : "not set", "\n";
  print "Bit 3 is ", $bitset->get(3) ? "set" : "not set", "\n";

  undef $bitset;  ## free the bitset

=item Example 2: Comparison operations between bitsets

This example illustrates the use of the comparison functions provided by the 
C<Bit::Set::OO> module. The equality comparison function is shown for simplicity, 
but the example can serve as blue print for other comparisons functions e.g. 
less than equal to.

  use Bit::Set::OO;    ## OO interface to Bit C library

  my $set1 = Bit::Set->new(64);
  my $set2 = Bit::Set->new(64);

  $set1->set(1);
  $set1->set(3);
  $set1->set(5);

  $set2->set(1);
  $set2->set(3);
  $set2->set(5);

  if ( $set1->eq($set2) ) {
      print "The two bitsets are equal\n";
  } else {
      print "The two bitsets are not equal\n";
  }

  undef $set1;
  undef $set2;

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

=item B<Implement Performant Object Oriented interfaces> 

Explore Joe Scahefer's L<sealed|https://metacpan.org/pod/sealed>  in order to 
create efficient OO interfaces without the overhead of traditional Perl OO 
systems by "sealing" the methods at compile time. Subroutine attribute for 
compile-time method lookups on its typed lexicals. 
As Joe L<points out|https://www.iconoclasts.blog/joe/perl7-sealed-lexicals>:

    "Perl 5s OO runtime method lookup has 50% more performance overhead than a 
    direct, named subroutine invocation." 

Doug MacEachern proposed a very L<solution|https://www.perl.com/pub/2000/06/dougpatch.html/> which however never made it into the core. 
Joe's sealed package implements Doug's idea in a modern way, allowing the 
creation of efficient OO interfaces without the overhead of traditional Perl OO
systems by "sealing" the methods at compile time.

=back

=head1 AUTHOR

Christos Argyropoulos.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Christos Argyropoulos.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
