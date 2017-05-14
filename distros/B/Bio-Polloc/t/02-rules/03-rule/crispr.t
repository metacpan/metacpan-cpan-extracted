use strict;
use warnings;

use Test::More tests => 9;

#1
use_ok('Bio::Polloc::Rule::crispr');
use_ok('Bio::Seq');

SKIP: {
skip 'CRISPRFinder not available', 7 unless Bio::Polloc::Rule::crispr->_executable;

# 3
my $r = Bio::Polloc::RuleI->new(-type=>'crispr');
isa_ok($r, 'Bio::Polloc::Rule::crispr');

#4
$r->value({});
my $loci = $r->execute(-seq=>Bio::SeqIO->new(-file=>'t/crispr_seq.fasta')->next_seq);
isa_ok($loci, 'ARRAY');
is($#$loci, 0, 'Correct number of loci');

# 6
isa_ok($loci->[0], 'Bio::Polloc::Locus::crispr');
is($loci->[0]->from, 43, 'Correct origin of locus 1');
is($loci->[0]->strand, '.', 'Correct strand of locus 1');
is($loci->[0]->spacers_no, 87, 'Correct number of spacers');

}
