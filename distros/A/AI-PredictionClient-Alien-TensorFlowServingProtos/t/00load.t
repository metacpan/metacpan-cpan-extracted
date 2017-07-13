## no critic(RCS,VERSION,explicit,Module)
use strict;
use warnings;

use Test::More;

BEGIN {
    use_ok('AI::PredictionClient::Alien::TensorFlowServingProtos');
}
ok( 1, 'AI::PredictionClient::Alien::TensorFlowServingProtos.' );
done_testing();


