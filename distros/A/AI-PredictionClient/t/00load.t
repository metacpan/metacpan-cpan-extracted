## no critic(RCS,VERSION,explicit,Module)
use strict;
use warnings;

use Test::More;

BEGIN {
    use_ok('AI::PredictionClient::CPP::PredictionGrpcCpp');
}
ok( 1, 'AI::PredictionClient::CPP::PredictionGrpcCpp loaded.' );
done_testing();

