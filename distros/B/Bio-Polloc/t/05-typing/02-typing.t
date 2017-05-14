use strict;
use warnings;

use Test::More tests => 13;

# 1
use_ok('Bio::Polloc::TypingIO');

# 2
my $T = Bio::Polloc::TypingIO->new(-file=>'t/vntrs.bme')->typing;
isa_ok($T, 'Bio::Polloc::Typing::bandingPattern::amplification');

# 3
is($T->type, 'bandingPattern::amplification');

# 4
use_ok('Bio::Polloc::Genome');
use_ok('Bio::Polloc::LocusIO');
my $G = [Bio::Polloc::Genome->new(-file=>'t/repeats.fasta')];
my $L = Bio::Polloc::LocusIO->new(-file=>'t/loci_short.gff3')->read_loci(-genomes=>$G);

# 6
isa_ok($T->locigroup($L), 'Bio::Polloc::LociGroup');

# 7
SKIP: {
eval { $T->_load_module('Bio::Tools::Run::Alignment::Muscle') };
skip 'Bio::Tools::Run::Alignment::Muscle not installed', 7 if $@;

isa_ok($T->scan, 'Bio::Polloc::LociGroup');

# 8
my $NM = $T->matrix(-names=>1);
isa_ok($NM, 'HASH');
isa_ok($NM->{'repeats'}, 'ARRAY');
is($#{$NM->{'repeats'}}, 0);
is($NM->{'repeats'}->[0], 105);

# 12
my $BM = $T->binary(-names=>1);
isa_ok($BM, 'HASH');
is($BM->{'repeats'}, 1);
}

