use Test::More tests => 3;

BEGIN {
use_ok( 'BioX::SeqUtils::Promoter' );
}

use BioX::SeqUtils::Promoter;
use BioX::SeqUtils::Promoter::Sequence;

my $promoter = BioX::SeqUtils::Promoter->new();

ok($promoter, "promoter new");

$tstring = 'ATGCGNT';
$tstring2 = 'TANTCG';
$tstring3 = join('',$tstring,$tstring2);

#print $tstring3;

my $sequence = BioX::SeqUtils::Promoter::Sequence->new({ label => 'tagstring', sequence => $tstring });
$sequence->add_segment({sequence=>$tstring2});
my $seqstring = $sequence->get_sequence();
ok($tstring3 == $seqstring, "Sequence parameter");
