use Test::More tests => 2;

BEGIN {
use_ok( 'BioX::SeqUtils::Promoter' );
}

use BioX::SeqUtils::Promoter;

my $promoter = BioX::SeqUtils::Promoter->new();


ok($promoter, "promoter new");

