
use strict;
use warnings;

use Test::More tests => 1;
use Test::Differences;
use Color::Swatch::ASE::Writer;

# ABSTRACT: Test the start block type
my $structure = {
  signature => 'ASEF',
  version   => [ 1, 0 ],
  blocks    => [ { type => 'group_start' }, ]
};

my $out      = Color::Swatch::ASE::Writer->write_string($structure);
my $expected = 'ASEF';
$expected .= "\x{00}\x{01}\x{00}\x{00}";    # version
$expected .= "\x{00}\x{00}\x{00}\x{01}";    # numblocks

#---- block 1
$expected .= "\x{c0}\x{01}";                # group start
$expected .= "\x{00}\x{00}\x{00}\x{04}";    # block length = 4
$expected .= "\x{00}\x{0d}";                # block group = 13
$expected .= "\x{00}\x{00}";                # label is only a null terminator.

my (@chunks) = grep length, split /(.{0,4})/, $out;

my (@echunks) = grep length, split /(.{0,4})/, $expected;

eq_or_diff \@chunks, \@echunks;
