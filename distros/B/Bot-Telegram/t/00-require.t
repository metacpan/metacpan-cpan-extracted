use Mojo::Base -strict;
use lib 't/lib';

use Test::More tests => 2;

# Make sure our testing utilities are OK
eval {
  require Bot::Telegram::Test;
  require Bot::Telegram::Test::Updates;
};

if ($@) {
  diag $@;
  BAIL_OUT 'Testing library is broken, cannot continue';
}

require_ok 'Bot::Telegram';

subtest Exceptions => sub {
  require_ok 'Bot::Telegram::X::InvalidArgumentsError';
  require_ok 'Bot::Telegram::X::InvalidStateError';
};

done_testing;
