use strictures;
use Data::HAL qw();
use Test::Fatal qw(exception);
use Test::More import => [qw(done_testing isa_ok)];

isa_ok exception { Data::HAL->from_json('[]') }, 'failure::Data::HAL::InvalidJSON';
done_testing;
