package Cisco::Abbrev;

use warnings;
use strict;

=head1 NAME

Cisco::Abbrev - Translate to/from Cisco Interface Abbreviations

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';


=head1 SYNOPSIS

This module converts between Cisco canonical interface names
(i.e. GigabitEthernet0/1) and the abbreviated forms often output by their
devices (i.e. Gi0/1).

    use Cisco::Abbrev;

    my $long  = cisco_long_int('Gi0/1');      ## $long='GigabitEthernet0/1';
    my $short = cisco_abbrev_int('GigabitEthernet0/1');   ## $short='Gi0/1';

=cut

#################################################################

use base 'Exporter';
our @EXPORT = qw( cisco_abbrev_int cisco_long_int );

our %LONG = (
    'Fa' => 'FastEthernet',
    'Gi' => 'GigabitEthernet',
    'Te' => 'TenGigabitEthernet',
    'Et' => 'Ethernet',
    'Eth' => 'Ethernet',
    'Vl' => 'Vlan',
    'FD' => 'Fddi',
    'PortCh' => 'Port-channel',
    'Po' => 'Port-channel',

    'Tu' => 'Tunnel',
    'Lo' => 'Loopback',
    'Vi' => 'Virtual-Access',
    'Vt' => 'Virtual-Template',
    'EO'  => 'EOBC',

    'Se' => 'Serial',
    'PO' => 'POS',
    'PosCh' => 'Pos-channel',
    'Mu' => 'Multilink',
    'AT' => 'ATM',

    'Async' => 'Async',
    'Group-Async' => 'Group-Async',
    'MFR' => 'MFR',
);

our %ABBREV = reverse %LONG;
$ABBREV{'Port-channel'} = 'Po';  ## ambiguous
$ABBREV{'Ethernet'    } = 'Et';  ## ambiguous

## valid interface names and abbreviations match this regexp.
our $VALID = qr(^[A-Z][-A-Za-z\d/:.]+$)o;

#################################################################

=head1 FUNCTIONS

=head2 cisco_long_int($abbrev)

Returns the canonical interface name for an abbreviated form.  If the
interface type is not recognized, returns undef.

=cut

sub cisco_long_int { _convert(shift, \%LONG) }

#################################################################

=head2 cisco_abbrev_int($long)

Returns the abbreviated form of the canonical interface name.  If the
interface type is not recognized, returns undef.

=cut

sub cisco_abbrev_int { _convert(shift, \%ABBREV) }

#################################################################

sub _convert {
    my ($int, $lookup) = @_;

    return undef unless (defined $int and $int =~ $VALID);

    my ($type, $pos) = $int =~ qr/^(\D+)(.*)/o;
    my $other = $lookup->{$type} or return undef;
    return $other.$pos;
}

#################################################################

=head1 OTHER INTERFACE TYPES

If you find any interface types that this module does not handle
correctly, please notify the author via CPAN's request system:

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Cisco-Abbrev>

=head1 AUTHOR

kevin brintnall, C<< <kbrint at rufus.net> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008 kevin brintnall, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Cisco::Abbrev
