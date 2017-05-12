
use strict;
use warnings;

use Test::More tests => 1;
use Test::Differences;
use Color::Swatch::ASE::Writer;

# ABSTRACT: Test block labels

my $structure = {
  signature => 'ASEF',
  version   => [ 1, 0 ],
  blocks    => [ { type => 'group_start', label => "Various", }, ]
};

my $out      = Color::Swatch::ASE::Writer->write_string($structure);
my $expected = 'ASEF';
$expected .= "\x{00}\x{01}\x{00}\x{00}";                            # version
$expected .= "\x{00}\x{00}\x{00}\x{01}";                            # numblocks
                                                                    # block 1
$expected .= "\x{c0}\x{01}";                                        # group start
$expected .= "\x{00}\x{00}\x{00}\x{12}";                            # block length = 18
$expected .= "\x{00}\x{0d}";                                        # block group = 13
$expected .= "\x{00}\x{56}\x{00}\x{61}\x{00}\x{72}\x{00}\x{69}";    # "Vari" in UTF16-BE
$expected .= "\x{00}\x{6f}\x{00}\x{75}\x{00}\x{73}";                # "ous" in UTF16-BE
$expected .= "\x{00}\x{00}";                                        # label null terminator.

my (@chunks)  = grep length, split /(.{0,4})/, $out;
my (@echunks) = grep length, split /(.{0,4})/, $expected;

eq_or_diff \@chunks, \@echunks;
