package Bit::Set::DB::SETOP_COUNT_OPTS;
$Bit::Set::DB::SETOP_COUNT_OPTS::VERSION = '0.13';
use strict;
use warnings;

require XSLoader;
XSLoader::load('Bit::Set::DB::SETOP_COUNT_OPTS');

1;

__END__

=head1 NAME

Bit::Set::DB::SETOP_COUNT_OPTS - Configuration options for container set operations

=head1 VERSION

version 0.13

=head1 SYNOPSIS

    use Bit::Set::DB::SETOP_COUNT_OPTS;

    # Create with default options
    my $opts = Bit::Set::DB::SETOP_COUNT_OPTS->new();

    # Create with custom options for container operations
    my $opts = Bit::Set::DB::SETOP_COUNT_OPTS->new({
        device_id => 1,              # Use GPU (0 = CPU, 1 = GPU)
        upd_1st_operand => 1,        # Update first container during operation
        upd_2nd_operand => 0,        # Don't update second container
        release_1st_operand => 1,    # Release first container after operation
        release_2nd_operand => 1,    # Release second container after operation
        release_counts => 0          # Keep count results in memory
    });

    # Or using key-value pairs
    my $opts = Bit::Set::DB::SETOP_COUNT_OPTS->new(
        device_id => 0,              # Use CPU
        release_counts => 1          # Release count results after operation
    );

=head1 DESCRIPTION

This class provides configuration options for container set operations in the Bit::Set::DB2 module.
Container operations perform set operations (intersection, union, difference, minus) between two
bitset containers, count the results, and optionally store them in buffers.

These options control device selection (CPU/GPU), operand update behavior during operations,
and memory management for both input containers and output count results.

=head1 METHODS

=head2 new([%options])

Creates a new SETOP_COUNT_OPTS object with configuration options for container operations.
Can be called with no arguments for defaults, or with a hash reference of options, or with key-value pairs.

=head2 device_id([$value])

Gets or sets the device ID for container operations (0 = CPU, 1 = GPU, etc.).

=head2 upd_1st_operand([$value])

Gets or sets whether to update the first container during set operations.

=head2 upd_2nd_operand([$value])

Gets or sets whether to update the second container during set operations.

=head2 release_1st_operand([$value])

Gets or sets whether to release the first container from memory after operations complete.

=head2 release_2nd_operand([$value])

Gets or sets whether to release the second container from memory after operations complete.

=head2 release_counts([$value])

Gets or sets whether to release count results from memory after operations complete.

=head1 SEE ALSO

 L<Bit::Set::DB>, L<Bit::Set>

=head1 AUTHOR

Christos Argyropoulos 2026

=cut
