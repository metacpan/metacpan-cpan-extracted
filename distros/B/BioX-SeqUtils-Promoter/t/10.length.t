use Test::More tests => 2;

BEGIN {
use_ok( 'BioX::SeqUtils::Promoter::Base' );
}

# this should make a sequence 100 long
my $DNA = 'ACTG' x 25;
my $answer = 100;

my $baseobj = BioX::SeqUtils::Promoter::Base->new();

my $test = $baseobj->length({ string => $DNA});

ok($test == $answer, "Length method works");
