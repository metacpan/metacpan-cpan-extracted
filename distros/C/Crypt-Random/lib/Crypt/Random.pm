##
## Crypt::Random -- Interface to /dev/random and /dev/urandom.
##
## Copyright (c) 1998-2018, Vipul Ved Prakash.  All rights reserved.
## This code is free software; you can redistribute it and/or modify
## it under the same terms as Perl itself.

use strict;
use warnings;
package Crypt::Random; 
require Exporter;
use vars qw($VERSION @EXPORT_OK); 

BEGIN {
    *import = \&Exporter::import;
    @EXPORT_OK = qw( makerandom makerandom_itv makerandom_octet );
}

use Math::Pari qw(PARI floor Mod pari2pv pari2num lift); 
use Carp; 
use Data::Dumper;
use Class::Loader;
use Crypt::Random::Generator;

our $VERSION = '1.57';

sub _pickprovider { 

    my (%params) = @_;

    return $params{Provider} if $params{Provider};
    $params{Strength} = defined $params{Strength} ? $params{Strength} : 1;
    my $gen = Crypt::Random::Generator->new( ( Strength => $params{Strength} ));
    return $gen->{Provider};

}

sub makerandom { 

    my ( %params ) = @_;

    $params{Verbosity} = 0 unless $params{Verbosity};
    my $uniform = $params{Uniform} || 0;
    local $| = 1;

    my $provider = _pickprovider(%params);
    my $loader = Class::Loader->new();
    my $po = $loader->_load ( Module => "Crypt::Random::Provider::$provider", 
                              Args => [ map { $_ => $params{$_} }
                                qw(Strength Provider) ] )

        or die "Unable to load module Crypt::Random::Provider::$provider - $!";
    my $r = $po->get_data( %params );

    my $size     = $params{Size};
    unless ($size) { die "makerandom() called without 'Size' parameter." }

    my $down     = $size - 1;

    my $y;
    unless ($uniform) { 

        # We always set the high bit of the random number if 
        # we want the result to occupy exactly $size bits.

        $y = unpack "H*",     pack "B*", '0' x ( $size%8 ? 8-$size % 8 : 0 ). '1'.
             unpack "b$down", $r;

    } else { 

        # If $uniform is set, $size of 2 could return 00 
        # and 01 in addition to 10 and 11. 00 and 01 can 
        # be represented in less than 2 bits, but 
        # the result of this generation is uniformaly 
        # distributed.

        $y = unpack "H*",     pack "B*", '0' x ( $size%8 ? 8-$size % 8 : 0 ).
             unpack "b$size", $r;

    }

    return Math::Pari::_hex_cvt ( "0x$y" );

}


sub makerandom_itv { 

    my ( %params ) = @_; 

    my $a  = $params{ Lower } || 0; $a = PARI ( $a ); 
    my $b  = $params{ Upper }; $b = PARI ( $b );

    unless ($b) { 
        die "makerandom_itv needs 'Upper' parameter."
    }

    my $itv    = Mod ( 0, $b - $a );
    my $size   = length ( $itv ) * 5;
    #my $random = makerandom %params, Size => $size; # extra we can get rid of it

    my $random;
    do { $random = makerandom %params, Size => $size, Uniform => 1 } # should always be uniform
    while ( $random >= (PARI(2)**$size) - ((PARI(2)**$size) % lift($b-$a)));

    $itv += $random; 
    my $r = PARI ( lift ( $itv ) + $a );

    undef $itv; undef $a; undef $b; 
    return "$r";

}


sub makerandom_octet  {

    my ( %params ) = @_; 

    $params{Verbosity} = 0 unless $params{Verbosity};

    my $provider = _pickprovider(%params); 
    my $loader = Class::Loader->new();
    my $po = $loader->_load ( Module => "Crypt::Random::Provider::$provider", 
                              Args => [ %params ] );
    return $po->get_data( %params );


}


'True Value';

=head1 NAME

Crypt::Random - Cryptographically Secure, True Random Number Generator. 

=head1 SYNOPSIS

 use Crypt::Random qw( makerandom ); 
 my $r = makerandom ( Size => 512, Strength => 1 ); 

=head1 DESCRIPTION

Crypt::Random is an interface module to the /dev/random and /dev/urandom
device found on most modern unix systems. It also interfaces with egd,
a user space entropy gathering daemon, available for systems where
/dev/random (or similar) devices are not available. When Math::Pari is
installed, Crypt::Random can generate random integers of arbitrary size
of a given bitsize or in a specified interval.

=head1 ALTERNATIVES

Crypt::Random has numerous options for obtaining randomness.  If you would
prefer a simpler module that provides cryptographic grade randomness
Crypt::URandom should be considered.

The CPANSec group has developed the L<CPAN Author's Guide to Random Data for Security|https://security.metacpan.org/docs/guides/random-data-for-security.html> that should be reviewed before dealing with randomness. 

=head1 BLOCKING BEHAVIOUR

Since kernel version 5.6 in 2020, /dev/random is no longer blocking and
there is effectively no difference between /dev/random and /dev/urandom.
Indeed there has been no difference in the quality of randomness from
either in many years.  /dev/random now only blocks on startup of the
system and only for a very short time.

=head1 HARDWARE RNG

If there's a hardware random number generator available, for instance
the Intel i8x0 random number generator, you can use it instead of
/dev/random or /dev/urandom.  Usually your OS will provide access to the
RNG as a device, eg (/dev/intel_rng).

=head1 METHODS 

=over 4

=item B<makerandom()>

Generates a random number of requested bitsize in base 10. Following
arguments can be specified.

=over 4

=item B<Size> 

Bitsize of the random number. 

=item B<Provider> 

Specifies the name of the Provider to be used. B<Specifying a Provider overrides Strength>.

Options are:

=over 4

=item devrandom

Uses /dev/random to generate randomness.

=item devurandom

Uses /dev/urandom to generate randomness.

=item Win32API

Uses the Windows API SystemFunction036 (RtlGenRandom) to generate
randomness on Windows Operating Systems.

=item egd (INSECURE)

An Entropy Gathering Daemon (egd) daemon is read to obtain randomness.
As egd has not been updated since 2002 it has been moved to the low
strength provider list.

=item rand

Generates randomness based on Perl's Crypt::URandom urandom function.

=back

=item B<Strength> 0 || 1 

Value of 1 implies that /dev/random or /dev/urandom should be used
for requesting random bits while 0 implies insecure including rand.

As of release 1.55 Strength defaults to 1 (/dev/random or
/dev/urandom or rand (using Crypt::URandom::urandom))

=item B<Device> 

Alternate device to request random bits from. 

=item B<Uniform> 0 || 1

Value of 0 (default) implies that the high bit of the generated random
number is always set, ensuring the bitsize of the generated random will be
exactly Size bits. For uniformly distributed random numbers, Uniform
should be set to 1.

=back 

=item B<makerandom_itv()> 

Generates a random number in the specified interval.  In addition 
to the arguments to makerandom() following attributes can be 
specified. 

=over 4

=item B<Lower> 

Inclusive Lower limit.  

=item B<Upper> 

Exclusive Upper limit. 

=back 

=item B<makerandom_octet()>

Generates a random octet string of specified length. In addition to
B<Strength>, B<Device> and B<Verbosity>, following arguments can be
specified.

=over 4

=item B<Length>

Length of the desired octet string. 

=item B<Skip>

An octet string consisting of characters to be skipped while reading from
the random device.

=back

=back

=head1 DEPENDENCIES

Crypt::Random needs Math::Pari 2.001802 or higher. 

=head1 SEE ALSO

Crypt::URandom should be considered as simpler module for obtaining
cryptographically secure source of Randomness.

The CPANSec group has developed the L<CPAN Author's Guide to Random Data for Security|https://security.metacpan.org/docs/guides/random-data-for-security.html> that should be reviewed before dealing with randomness. 

=head1 BIBLIOGRAPHY 

=over 4

=item 1 random.c by Theodore Ts'o.  Found in drivers/char directory of 
the Linux kernel sources.

=item 2 Handbook of Applied Cryptography by Menezes, Paul C. van Oorschot
and Scott Vanstone.

=back

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 AUTHOR

Vipul Ved Prakash, <mail@vipul.net>

=cut

