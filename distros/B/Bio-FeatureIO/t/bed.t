# -*-Perl-*- Test Harness script for Bioperl
# $Id: FeatureIO.t 15112 2008-12-08 18:12:38Z sendu $

use strict;
use warnings;
use Bio::Root::Test;
use Bio::FeatureIO;

my ($io, $f, $s, $fcount, $scount);

################################################################################
#
# use FeatureIO::bed to read a bed file
#
ok($io = Bio::FeatureIO->new(-file => test_input_file('1.bed')));

ok($f = $io->next_feature);
# Check correct conversion of [0, feature-end+1) bed-coordinates into [1, feature-end]
# bioperl coordinates.  (here: bed [0, 10))
is($f->start, 1);
is($f->end, 10);

# Check field values.
my @tags = $f->get_tag_values("Name");
is(scalar(@tags), 1);
is($tags[0], "test-coordinates-1");

is($f->seq_id, "chr1");

done_testing();

exit;
