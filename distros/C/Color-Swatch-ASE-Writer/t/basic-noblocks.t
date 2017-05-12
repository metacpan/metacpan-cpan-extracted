
use strict;
use warnings;

use Test::More tests => 1;
use Test::Differences;
use Color::Swatch::ASE::Writer;

# ABSTRACT: Test basic structure production

my $structure = {
  signature => 'ASEF',
  version   => [ 1, 0 ],
  blocks    => []
};

my $out = Color::Swatch::ASE::Writer->write_string($structure);

my $expected = 'ASEF';
$expected .= "\x{00}\x{01}\x{00}\x{00}";    # version
$expected .= "\x{00}\x{00}\x{00}\x{00}";    # num blocks

my (@chunks)  = grep length, split /(.{0,4})/, $out;
my (@echunks) = grep length, split /(.{0,4})/, $expected;

eq_or_diff \@chunks, \@chunks;
