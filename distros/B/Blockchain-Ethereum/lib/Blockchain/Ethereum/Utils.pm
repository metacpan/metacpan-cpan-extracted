package Blockchain::Ethereum::Utils;

use v5.26;
use strict;
use warnings;

# ABSTRACT: Utility functions for Ethereum operations
our $AUTHORITY = 'cpan:REFECO';    # AUTHORITY
our $VERSION   = '0.020';          # VERSION

use Carp;
use Math::BigInt;
use Math::BigFloat;
use Scalar::Util qw(looks_like_number);
use Exporter 'import';

our @EXPORT = qw(
    parse_units format_units
    WEI KWEI MWEI GWEI SZABO FINNEY ETHER ETH
);

use constant {
    WEI    => 0,
    KWEI   => 3,
    MWEI   => 6,
    GWEI   => 9,
    SZABO  => 12,
    FINNEY => 15,
    ETHER  => 18,
    ETH    => 18,    # alias for ether
};

my %ETHEREUM_UNITS = (
    'wei'    => WEI,
    'kwei'   => KWEI,
    'mwei'   => MWEI,
    'gwei'   => GWEI,
    'szabo'  => SZABO,
    'finney' => FINNEY,
    'ether'  => ETHER,
    'eth'    => ETH,
);

sub _process_units {
    my ($value, $unit, $processor) = @_;

    croak "Invalid number format" unless defined $value && looks_like_number($value);
    croak "Unknown unit"          unless defined $unit;

    my $decimals =
          $unit =~ /^\d+$/                  ? $unit
        : exists $ETHEREUM_UNITS{lc($unit)} ? $ETHEREUM_UNITS{lc($unit)}
        :                                     croak "Unknown unit";

    return $processor->(Math::BigFloat->new($value), Math::BigInt->new(10)->bpow($decimals));
}

sub parse_units {
    my ($value, $unit) = @_;
    return _process_units($value, $unit, sub { Math::BigInt->new($_[0]->bmul($_[1]))->bstr() });
}

sub format_units {
    my ($value, $unit) = @_;
    return _process_units($value, $unit, sub { $_[0]->bdiv($_[1])->bstr() });
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Blockchain::Ethereum::Utils - Utility functions for Ethereum operations

=head1 VERSION

version 0.020

=head1 SYNOPSIS

    use Blockchain::Ethereum::Utils;
    
    # Convert human-readable values to wei
    my $wei = parse_units('1.5', ETHER);
    
    # Convert wei back to human-readable format
    my $eth = format_units($wei, ETHER);
    
    # Use unit constants for clarity
    my $gwei_amount = parse_units('20', GWEI);

=head1 DESCRIPTION

This module provides utilities for Ethereum unit conversions. Currently focused 
on converting between different Ethereum denominations (wei, gwei, ether, etc.).

Additional Ethereum-related utilities may be added in future versions.

=head1 METHODS

=head2 parse_units

Converts a human-readable value to the smallest unit (wei equivalent)

=over 4

=item * C<$value> - The numeric value to convert. Can be integer, decimal, or scientific notation

=item * C<$unit> - The unit to convert from. Can be:
  - A unit constant: WEI, KWEI, MWEI, GWEI, SZABO, FINNEY, ETHER, ETH
  - A unit string: 'wei', 'kwei', 'mwei', 'gwei', 'szabo', 'finney', 'ether', 'eth'
  - A number representing decimal places: 0-18

=back

A string representation of the value in the smallest unit (wei equivalent)

    parse_units('1.5', ETHER)     # Returns '1500000000000000000'
    parse_units('20', GWEI)       # Returns '20000000000'
    parse_units('100', 'mwei')    # Returns '100000000'
    parse_units('5.5', 6)         # Returns '5500000'

=head2 format_units

Converts a value from the smallest unit (wei equivalent) to a human-readable format

=over 4

=item * C<$value> - The value in smallest units to convert

=item * C<$unit> - The unit to convert to. Same options as parse_units

=back

A string representation of the formatted value with trailing zeros removed.

    format_units('1500000000000000000', ETHER)  # Returns '1.5'
    format_units('20000000000', GWEI)           # Returns '20'
    format_units('100000000', 'mwei')           # Returns '100'
    format_units('5500000', 6)                  # Returns '5.5'

=head1 AUTHOR

REFECO <refeco@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by REFECO.

This is free software, licensed under:

  The MIT (X11) License

=cut
