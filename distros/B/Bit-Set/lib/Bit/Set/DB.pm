#!/home/chrisarg/perl5/perlbrew/perls/current/bin/perl
package Bit::Set::DB;
$Bit::Set::DB::VERSION = '0.01';
use strict;
use warnings;
use FFI::Platypus::Record;

# Define the record class as a nested package
{

    package Bit::Set::DB::SETOP_COUNT_OPTS;
$Bit::Set::DB::SETOP_COUNT_OPTS::VERSION = '0.01';
use FFI::Platypus::Record;
    record_layout_1(
        'int'  => 'num_cpu_threads',
        'int'  => 'device_id',
        'bool' => 'upd_1st_operand',
        'bool' => 'upd_2nd_operand',
        'bool' => 'release_1st_operand',
        'bool' => 'release_2nd_operand',
        'bool' => 'release_counts',
    );
}

use FFI::Platypus;
use Alien::Bit;


# Set up the FFI object
my $ffi = FFI::Platypus->new( api => 2 );
$ffi->lib( Alien::Bit->dynamic_libs );

# Define opaque types
$ffi->type( 'opaque' => 'Bit_DB_T' );
$ffi->type( 'opaque' => 'Bit_T' );

# LLM did not create an opaque pointer to a pointer
$ffi->type( 'opaque*' => 'Bit_DB_T_Ptr' );

# Register the nested record class as a type
$ffi->type( 'record(Bit::Set::DB::SETOP_COUNT_OPTS)' => 'SETOP_COUNT_OPTS_t' )
  ;    ## LMM didn't generate the record token in the definition

# Define a helper for debug checks
# LLM provided this: use constant DEBUG => $ENV{DEBUG};
BEGIN {
    use constant DEBUG => $ENV{DEBUG} // 0;
    if (DEBUG) {
        print "* Debugging is enabled\n";
    }
}

# Function definitions for FFI attachment
my %functions = (

    # Creation / Destruction
    BitDB_new => {
        args  => [ 'int', 'int' ],
        ret   => 'Bit_DB_T',
        check => sub {
            my ( $length, $num_of_bitsets ) = @_;
            die "BitDB_new: length must be >= 0 and <= INT_MAX"
              if $length < 0 || $length > 2147483647;
            die "BitDB_new: num_of_bitsets must be >= 0 and <= INT_MAX"
              if $num_of_bitsets < 0 || $num_of_bitsets > 2147483647;
        }
    },
    BitDB_free => {
        args => ['Bit_DB_T_Ptr'],
        ret  => 'opaque',
    },

    # Properties
    BitDB_length => {
        args  => ['Bit_DB_T'],
        ret   => 'int',
        check => sub {
            my ($set) = @_;
            die "BitDB_length: set cannot be NULL" if !defined $set;
        }
    },
    BitDB_nelem => {
        args  => ['Bit_DB_T'],
        ret   => 'int',
        check => sub {
            my ($set) = @_;
            die "BitDB_nelem: set cannot be NULL" if !defined $set;
        }
    },
    BitDB_count_at => {
        args  => [ 'Bit_DB_T', 'int' ],
        ret   => 'int',
        check => sub {
            my ( $set, $index ) = @_;
            die "BitDB_count_at: set cannot be NULL" if !defined $set;
            die "BitDB_count_at: index must be >= 0" if $index < 0;
        }
    },
    BitDB_count => {
        args  => ['Bit_DB_T'],
        ret   => 'int*',
        check => sub {
            my ($set) = @_;
            die "BitDB_count: set cannot be NULL" if !defined $set;
        }
    },

    # Manipulation
    BitDB_get_from => {
        args  => [ 'Bit_DB_T', 'int' ],
        ret   => 'Bit_T',
        check => sub {
            my ( $set, $index ) = @_;
            die "BitDB_get_from: set cannot be NULL" if !defined $set;
            die "BitDB_get_from: index must be >= 0" if $index < 0;
        }
    },
    BitDB_put_at => {
        args  => [ 'Bit_DB_T', 'int', 'Bit_T' ],
        ret   => 'void',
        check => sub {
            my ( $set, $index, $bitset ) = @_;
            die "BitDB_put_at: set cannot be NULL"    if !defined $set;
            die "BitDB_put_at: index must be >= 0"    if $index < 0;
            die "BitDB_put_at: bitset cannot be NULL" if !defined $bitset;
        }
    },
    BitDB_extract_from => {
        args  => [ 'Bit_DB_T', 'int', 'opaque' ],
        ret   => 'int',
        check => sub {
            my ( $set, $index, $buffer ) = @_;
            die "BitDB_extract_from: set cannot be NULL"    if !defined $set;
            die "BitDB_extract_from: index must be >= 0"    if $index < 0;
            die "BitDB_extract_from: buffer cannot be NULL" if !defined $buffer;
        }
    },
    BitDB_replace_at => {
        args  => [ 'Bit_DB_T', 'int', 'opaque' ],
        ret   => 'void',
        check => sub {
            my ( $set, $index, $buffer ) = @_;
            die "BitDB_replace_at: set cannot be NULL"    if !defined $set;
            die "BitDB_replace_at: index must be >= 0"    if $index < 0;
            die "BitDB_replace_at: buffer cannot be NULL" if !defined $buffer;
        }
    },
    BitDB_clear => {
        args  => ['Bit_DB_T'],
        ret   => 'void',
        check => sub {
            my ($set) = @_;
            die "BitDB_clear: set cannot be NULL" if !defined $set;
        }
    },
    BitDB_clear_at => {
        args  => [ 'Bit_DB_T', 'int' ],
        ret   => 'void',
        check => sub {
            my ( $set, $index ) = @_;
            die "BitDB_clear_at: set cannot be NULL" if !defined $set;
            die "BitDB_clear_at: index must be >= 0" if $index < 0;
        }
    },

    # SETOP Count Store CPU
    BitDB_inter_count_store_cpu => {
        args  => [ 'Bit_DB_T', 'Bit_DB_T', 'int*', 'SETOP_COUNT_OPTS_t' ],
        ret   => 'int*',
        check => sub {
            my ( $bit, $bits, $buffer, $opts ) = @_;
            die "BitDB_inter_count_store_cpu: containers cannot be NULL"
              if !defined $bit || !defined $bits;
            die "BitDB_inter_count_store_cpu: buffer cannot be NULL"
              if !defined $buffer;
        }
    },
    BitDB_union_count_store_cpu => {
        args  => [ 'Bit_DB_T', 'Bit_DB_T', 'int*', 'SETOP_COUNT_OPTS_t' ],
        ret   => 'int*',
        check => sub {
            my ( $bit, $bits, $buffer, $opts ) = @_;
            die "BitDB_union_count_store_cpu: containers cannot be NULL"
              if !defined $bit || !defined $bits;
            die "BitDB_union_count_store_cpu: buffer cannot be NULL"
              if !defined $buffer;
        }
    },
    BitDB_diff_count_store_cpu => {
        args  => [ 'Bit_DB_T', 'Bit_DB_T', 'int*', 'SETOP_COUNT_OPTS_t' ],
        ret   => 'int*',
        check => sub {
            my ( $bit, $bits, $buffer, $opts ) = @_;
            die "BitDB_diff_count_store_cpu: containers cannot be NULL"
              if !defined $bit || !defined $bits;
            die "BitDB_diff_count_store_cpu: buffer cannot be NULL"
              if !defined $buffer;
        }
    },
    BitDB_minus_count_store_cpu => {
        args  => [ 'Bit_DB_T', 'Bit_DB_T', 'int*', 'SETOP_COUNT_OPTS_t' ],
        ret   => 'int*',
        check => sub {
            my ( $bit, $bits, $buffer, $opts ) = @_;
            die "BitDB_minus_count_store_cpu: containers cannot be NULL"
              if !defined $bit || !defined $bits;
            die "BitDB_minus_count_store_cpu: buffer cannot be NULL"
              if !defined $buffer;
        }
    },

    # SETOP Count Store GPU
    BitDB_inter_count_store_gpu => {
        args  => [ 'Bit_DB_T', 'Bit_DB_T', 'int*', 'SETOP_COUNT_OPTS_t' ],
        ret   => 'int*',
        check => sub {
            my ( $bit, $bits, $buffer, $opts ) = @_;
            die "BitDB_inter_count_store_gpu: containers cannot be NULL"
              if !defined $bit || !defined $bits;
            die "BitDB_inter_count_store_gpu: buffer cannot be NULL"
              if !defined $buffer;
        }
    },
    BitDB_union_count_store_gpu => {
        args  => [ 'Bit_DB_T', 'Bit_DB_T', 'int*', 'SETOP_COUNT_OPTS_t' ],
        ret   => 'int*',
        check => sub {
            my ( $bit, $bits, $buffer, $opts ) = @_;
            die "BitDB_union_count_store_gpu: containers cannot be NULL"
              if !defined $bit || !defined $bits;
            die "BitDB_union_count_store_gpu: buffer cannot be NULL"
              if !defined $buffer;
        }
    },
    BitDB_diff_count_store_gpu => {
        args  => [ 'Bit_DB_T', 'Bit_DB_T', 'int*', 'SETOP_COUNT_OPTS_t' ],
        ret   => 'int*',
        check => sub {
            my ( $bit, $bits, $buffer, $opts ) = @_;
            die "BitDB_diff_count_store_gpu: containers cannot be NULL"
              if !defined $bit || !defined $bits;
            die "BitDB_diff_count_store_gpu: buffer cannot be NULL"
              if !defined $buffer;
        }
    },
    BitDB_minus_count_store_gpu => {
        args  => [ 'Bit_DB_T', 'Bit_DB_T', 'int*', 'SETOP_COUNT_OPTS_t' ],
        ret   => 'int*',
        check => sub {
            my ( $bit, $bits, $buffer, $opts ) = @_;
            die "BitDB_minus_count_store_gpu: containers cannot be NULL"
              if !defined $bit || !defined $bits;
            die "BitDB_minus_count_store_gpu: buffer cannot be NULL"
              if !defined $buffer;
        }
    },

    # SETOP Count CPU
    BitDB_inter_count_cpu => {
        args  => [ 'Bit_DB_T', 'Bit_DB_T', 'SETOP_COUNT_OPTS_t' ],
        ret   => 'int*',
        check => sub {
            my ( $bit, $bits, $opts ) = @_;
            die "BitDB_inter_count_cpu: containers cannot be NULL"
              if !defined $bit || !defined $bits;
        }
    },
    BitDB_union_count_cpu => {
        args  => [ 'Bit_DB_T', 'Bit_DB_T', 'SETOP_COUNT_OPTS_t' ],
        ret   => 'int*',
        check => sub {
            my ( $bit, $bits, $opts ) = @_;
            die "BitDB_union_count_cpu: containers cannot be NULL"
              if !defined $bit || !defined $bits;
        }
    },
    BitDB_diff_count_cpu => {
        args  => [ 'Bit_DB_T', 'Bit_DB_T', 'SETOP_COUNT_OPTS_t' ],
        ret   => 'int*',
        check => sub {
            my ( $bit, $bits, $opts ) = @_;
            die "BitDB_diff_count_cpu: containers cannot be NULL"
              if !defined $bit || !defined $bits;
        }
    },
    BitDB_minus_count_cpu => {
        args  => [ 'Bit_DB_T', 'Bit_DB_T', 'SETOP_COUNT_OPTS_t' ],
        ret   => 'int*',
        check => sub {
            my ( $bit, $bits, $opts ) = @_;
            die "BitDB_minus_count_cpu: containers cannot be NULL"
              if !defined $bit || !defined $bits;
        }
    },

    # SETOP Count GPU
    BitDB_inter_count_gpu => {
        args  => [ 'Bit_DB_T', 'Bit_DB_T', 'SETOP_COUNT_OPTS_t' ],
        ret   => 'int*',
        check => sub {
            my ( $bit, $bits, $opts ) = @_;
            die "BitDB_inter_count_gpu: containers cannot be NULL"
              if !defined $bit || !defined $bits;
        }
    },
    BitDB_union_count_gpu => {
        args  => [ 'Bit_DB_T', 'Bit_DB_T', 'SETOP_COUNT_OPTS_t' ],
        ret   => 'int*',
        check => sub {
            my ( $bit, $bits, $opts ) = @_;
            die "BitDB_union_count_gpu: containers cannot be NULL"
              if !defined $bit || !defined $bits;
        }
    },
    BitDB_diff_count_gpu => {
        args  => [ 'Bit_DB_T', 'Bit_DB_T', 'SETOP_COUNT_OPTS_t' ],
        ret   => 'int*',
        check => sub {
            my ( $bit, $bits, $opts ) = @_;
            die "BitDB_diff_count_gpu: containers cannot be NULL"
              if !defined $bit || !defined $bits;
        }
    },
    BitDB_minus_count_gpu => {
        args  => [ 'Bit_DB_T', 'Bit_DB_T', 'SETOP_COUNT_OPTS_t' ],
        ret   => 'int*',
        check => sub {
            my ( $bit, $bits, $opts ) = @_;
            die "BitDB_minus_count_gpu: containers cannot be NULL"
              if !defined $bit || !defined $bits;
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

# Verification that all C functions are mapped (excluding macros)
my @c_functions = qw(
  BitDB_new BitDB_free BitDB_length BitDB_nelem BitDB_count_at BitDB_count
  BitDB_get_from BitDB_put_at BitDB_extract_from BitDB_replace_at BitDB_clear BitDB_clear_at
  BitDB_inter_count_store_cpu BitDB_union_count_store_cpu BitDB_diff_count_store_cpu BitDB_minus_count_store_cpu
  BitDB_inter_count_store_gpu BitDB_union_count_store_gpu BitDB_diff_count_store_gpu BitDB_minus_count_store_gpu
  BitDB_inter_count_cpu BitDB_union_count_cpu BitDB_diff_count_cpu BitDB_minus_count_cpu
  BitDB_inter_count_gpu BitDB_union_count_gpu BitDB_diff_count_gpu BitDB_minus_count_gpu
);

my %perl_functions;
@perl_functions{ keys %functions } = ();
for my $c_func (@c_functions) {
    die "FATAL: C function '$c_func' not implemented in Bit::Set::DB"
      unless exists $perl_functions{$c_func};
}

1;

# LLM forgot to export the Bit::Set functions
use Exporter 'import';
our @EXPORT_OK   = keys %functions;
our %EXPORT_TAGS = ( all => [@EXPORT_OK] );

__END__

=head1 NAME

Bit::Set::DB - Perl interface for bitset containers from the 'bit' C library

=head1 VERSION

version 0.01

=head1 SYNOPSIS

  use Bit::Set::DB;
  use Bit::Set;

  # Create a new bitset database
  my $db = BitDB_new(1024, 10);

  # Create a bitset and add it to the database
  my $set = Bit::Set::Bit_new(1024);
  Bit::Set::Bit_bset($set, 42);
  BitDB_put_at($db, 0, $set);

  # Get population count at index
  my $count = BitDB_count_at($db, 0);

  # Free the database and bitset
  BitDB_free(\$db);
  Bit::Set::Bit_free(\$set);

=head1 DESCRIPTION

This module provides a procedural Perl interface to the C library 'bit.h',
for creating and manipulating containers of bitsets (BitDB). It uses
C<FFI::Platypus> to wrap the C functions and C<Alien::Bit> to locate and link
to the C library.

The API is a direct mapping of the C functions. For detailed semantics of each
function, please refer to the C<bit.h> header file documentation.

Runtime checks on arguments are performed if the C<DEBUG> environment variable
is set to a true value.

=head1 FUNCTIONS

=head2 Creation and Destruction

=over 4

=item B<BitDB_new(length, num_of_bitsets)>

Creates a new bitset container for C<num_of_bitsets> bitsets, each of C<length>.

=item B<BitDB_free(db_ref)>

Frees the memory associated with the bitset container. Expects a reference to the scalar holding the DB object.

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

=over 4

=item B<BitDB_inter_count_cpu(db1, db2, opts)>
=item B<BitDB_union_count_cpu(db1, db2, opts)>
=item B<BitDB_diff_count_cpu(db1, db2, opts)>
=item B<BitDB_minus_count_cpu(db1, db2, opts)>

Perform the respective set operation count on the CPU.

=item B<BitDB_inter_count_gpu(db1, db2, opts)>
=item B<BitDB_union_count_gpu(db1, db2, opts)>
=item B<BitDB_diff_count_gpu(db1, db2, opts)>
=item B<BitDB_minus_count_gpu(db1, db2, opts)>

Perform the respective set operation count on the GPU.

=item B<BitDB_inter_count_store_cpu(db1, db2, buffer, opts)>
=item B<BitDB_union_count_store_cpu(db1, db2, buffer, opts)>
=item B<BitDB_diff_count_store_cpu(db1, db2, buffer, opts)>
=item B<BitDB_minus_count_store_cpu(db1, db2, buffer, opts)>

Perform the respective set operation count on the CPU and store results in C<buffer>.

=item B<BitDB_inter_count_store_gpu(db1, db2, buffer, opts)>
=item B<BitDB_union_count_store_gpu(db1, db2, buffer, opts)>
=item B<BitDB_diff_count_store_gpu(db1, db2, buffer, opts)>
=item B<BitDB_minus_count_store_gpu(db1, db2, buffer, opts)>

Perform the respective set operation count on the GPU and store results in C<buffer>.

=back

=head1 AUTHOR

GitHub Copilot (Claude Sonnet 4), guided by Christos Argyropoulos.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Christos Argyropoulos.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
