
use strict;
use warnings;

use Test::More tests => 1;
use Test::Differences;
use Color::Swatch::ASE::Writer;

# ABSTRACT: test Gray emitting

my $structure = {
  signature => 'ASEF',
  version   => [ 1, 0 ],
  blocks    => [
    {
      type  => 'group_start',
      label => "Various",
      group => 32,
    },
    {
      type   => "color",
      model  => 'Gray',
      values => [ 0.9, ]
    },
    {
      type => 'group_end',
    },
  ]
};

my $out      = Color::Swatch::ASE::Writer->write_string($structure);
my $expected = 'ASEF';
$expected .= "\x{00}\x{01}\x{00}\x{00}";    # version
$expected .= "\x{00}\x{00}\x{00}\x{03}";    # numblocks

#------- block 1
$expected .= "\x{c0}\x{01}";                                        # group start
$expected .= "\x{00}\x{00}\x{00}\x{12}";                            # block length = 18
$expected .= "\x{00}\x{20}";                                        # block group = 32
$expected .= "\x{00}\x{56}\x{00}\x{61}\x{00}\x{72}\x{00}\x{69}";    # "Vari" in UTF16-BE
$expected .= "\x{00}\x{6f}\x{00}\x{75}\x{00}\x{73}";                # "ous" in UTF16-BE
$expected .= "\x{00}\x{00}";                                        # label null terminator.

#-------- block 2

$expected .= "\x{00}\x{01}";                                        # color
$expected .= "\x{00}\x{00}\x{00}\x{0e}";                            # block length = 22
$expected .= "\x{00}\x{01}";                                        # block group = 1
$expected .= "\x{00}\x{00}";                                        # label null terminator
$expected .= "Gray";                                                # colour model

$expected .= "\x{3f}\x{66}\x{66}\x{66}";                            # 0.9 as a float ( gray )
$expected .= "\x{00}\x{02}";                                        # colour type

#---------------- block 3
$expected .= "\x{c0}\x{02}";                                        # group end
$expected .= "\x{00}\x{00}\x{00}\x{00}";                            # block length = 0

my (@chunks)  = grep length, split /(.{0,4})/, $out;
my (@echunks) = grep length, split /(.{0,4})/, $expected;

eq_or_diff \@chunks, \@echunks;
