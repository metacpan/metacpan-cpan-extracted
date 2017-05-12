#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 28;

BEGIN { use_ok('Algorithm::BinPack') };

my $bp = Algorithm::BinPack->new(binsize => 4);

isa_ok($bp, "Algorithm::BinPack");
is($bp->{binsize}, 4);

$bp->add_item(label => 'one',   size => 1);
$bp->add_item(label => 'two',   size => 2);
$bp->add_item(label => 'three', size => 3, misc => "This item is the best");
$bp->add_item(label => 'four',  size => 4, desc => "The fourth item");

my @bins = $bp->pack_bins;

# check pack order
is($bins[0]{items}[0]{label}, "four");
is($bins[1]{items}[0]{label}, "three");
is($bins[1]{items}[1]{label}, "one");
is($bins[2]{items}[0]{label}, "two");

# add items manually
$bp->prefill_bin(bin => 2, size => 3, label => 'manual',
                 manual => 'Item was added manually');
$bp->add_item(bin => 3, size => 4, label => 'another', meta => 'data');

@bins = $bp->pack_bins;

# check pack order
is($bins[0]{items}[0]{label}, "four");
is($bins[1]{items}[0]{label}, "three");
is($bins[1]{items}[1]{label}, "one");
is($bins[2]{items}[0]{label}, "manual");
is($bins[3]{items}[0]{label}, "another");
is($bins[4]{items}[0]{label}, "two");

# check extra keys
is($bins[0]{items}[0]{desc},   "The fourth item");
is($bins[1]{items}[0]{misc},   "This item is the best");
is($bins[2]{items}[0]{manual}, "Item was added manually");
is($bins[3]{items}[0]{meta},   "data");

# capture and test warning messages
my $warning;
$SIG{__WARN__} = sub { $warning = $_[0] };

# check for missing arguments
my @add_items = (
    [qw(label five)],
    [qw(size 5)],
);
my @prefill_bins = (
    [qw(      label Manual size 4)],
    [qw(bin 0              size 4)],
    [qw(bin 0 label Manual       )],
);

for (@add_items) {
    $warning = "";
    $bp->add_item(@$_);
    like($warning, qr/Missing argument/);
}

for (@prefill_bins) {
    $warning = "";
    $bp->prefill_bin(@$_);
    like($warning, qr/Missing argument/);
}

# check for too-big items
$warning = "";
$bp->prefill_bin(bin => 0, label => "Manual", size => 5);
like($warning, qr/too big/);

$warning = "";
$bp->add_item(bin => 0, label => "Manual", size => 5);
like($warning, qr/too big/);

$warning = "";
$bp->prefill_bin(bin => 0, label => "Manual", size => 4); # fill the bin up
$bp->prefill_bin(bin => 0, label => "Manual", size => 1); # try to add an item to go past full
like($warning, qr/too big/);

$warning = "";
$bp->add_item(bin => 0, label => "Manual", size => 1); # try to add an item to go past full
like($warning, qr/too big/);

$warning = "";
$bp->add_item(label => 'five', size  => 5);
$bp->pack_bins;
like($warning, qr/too big/);

# check for non-numeric bin
$warning = "";
$bp->prefill_bin(bin => 'a', label => "Manual", size => 4);
like($warning, qr/must be numeric/);
