#!/usr/bin/perl

use strict;
use warnings;

use Cisco::Abbrev;

use Test::More;

my @tests = map { chomp; [ split /\s+/ ] } grep /\S/, <DATA>;
my @lame = (undef, 'whatever', '1/42', '');

## can't be done in both directions.. just short --> long
my %ambiguous = (
    'PortCh5' => 'Port-channel5',
    'Eth0/5'  => 'Ethernet0/5',
);

plan tests => keys(%ambiguous) + 2*@tests + 2*@lame;

for my $test (@tests)
{
    my ($long, $short) = @$test;

    is(cisco_abbrev_int($long), $short, "abbrev($long) = $short");
    is(cisco_long_int($short), $long, "long_int($short) = $long");
}

## funky case of ambiguous abbrevs (depends on software version)
while (my ($short, $long) = each %ambiguous)
{
    is(cisco_long_int($short), $long, "long($short) = '$long'");
}

## handle undef inputs
for my $lame (@lame)
{
    no warnings 'uninitialized';
    is(cisco_long_int($lame), undef, "long($lame) = undef");
    is(cisco_long_int($lame), undef, "abbrev($lame) = undef");
}

__DATA__
FastEthernet0/1		Fa0/1
GigabitEthernet0/1	Gi0/1
TenGigabitEthernet0/1	Te0/1
Ethernet5		Et5
Vlan99			Vl99
Port-channel10		Po10
Tunnel504		Tu504
POS2/3/8		PO2/3/8
Serial4/44		Se4/44
Serial1/2/3:4/0.2	Se1/2/3:4/0.2
Multilink89		Mu89
Loopback0		Lo0
ATM4/3.1		AT4/3.1
Virtual-Access1.2438	Vi1.2438
Virtual-Template25	Vt25
Pos-channel5		PosCh5
Fddi8/2			FD8/2

EOBC0/0			EO0/0

MFR8			MFR8
Async5			Async5
Group-Async5		Group-Async5

FastEthernet1/0		Fa1/0
FastEthernet1/0.99	Fa1/0.99
GigabitEthernet0/2	Gi0/2
GigabitEthernet0/2.99	Gi0/2.99
Ethernet0/2		Et0/2
Ethernet0/2.99		Et0/2.99
TenGigabitEthernet1/1	Te1/1
TenGigabitEthernet1/1.99 Te1/1.99

POS2/0/0		PO2/0/0
Serial4/1/0		Se4/1/0
Serial4/1/0.500		Se4/1/0.500
ATM1/0/0		AT1/0/0
ATM1/0/0.45		AT1/0/0.45

Virtual-Access2589	Vi2589
Virtual-Access2.2589	Vi2.2589
