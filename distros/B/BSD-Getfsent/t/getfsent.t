#!/usr/bin/perl

use strict;
use warnings;

use BSD::Getfsent qw(getfsent);
use File::Spec;
use FindBin qw($Bin);
use Test::More tests => 7;

BAIL_OUT('unsupported OS') unless -e $BSD::Getfsent::FSTAB && -f _;

$BSD::Getfsent::FSTAB = File::Spec->catfile($Bin, 'data', 'getfsent.t.in');

my $entries_total = getfsent();

my @entries;
while (my @entry = getfsent()) {
    push @entries, [ @entry ];
}

is($entries_total, 5, 'total entries (scalar context)');
is(@entries, 5, 'total entries (list context)');

is_deeply($entries[0], [ '/dev/wd0a', '/',     'ffs', '',             'rw', 1, 1 ], '1st entry (/)');
is_deeply($entries[1], [ '/dev/wd0d', '/home', 'ffs', 'nodev,nosuid', 'rw', 1, 2 ], '2nd entry (/home)');
is_deeply($entries[2], [ '/dev/wd0e', '/tmp',  'ffs', 'nodev,nosuid', 'rw', 1, 2 ], '3rd entry (/tmp)');
is_deeply($entries[3], [ '/dev/wd0f', '/usr',  'ffs', 'nodev',        'rw', 1, 2 ], '4th entry (/usr)');
is_deeply($entries[4], [ '/dev/wd0g', '/var',  'ffs', 'nodev,nosuid', 'rw', 1, 2 ], '5th entry (/var)');
