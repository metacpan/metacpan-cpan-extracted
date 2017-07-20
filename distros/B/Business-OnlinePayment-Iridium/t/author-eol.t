
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Business/OnlinePayment/Iridium.pm',
    'lib/Business/OnlinePayment/Iridium/Action.pm',
    'lib/Business/OnlinePayment/Iridium/Action/CardDetailsTransaction.pm',
    'lib/Business/OnlinePayment/Iridium/Action/CrossReferenceTransaction.pm',
    'lib/Business/OnlinePayment/Iridium/Action/GetCardType.pm',
    'lib/Business/OnlinePayment/Iridium/Action/GetGatewayEntryPoints.pm',
    'lib/Business/OnlinePayment/Iridium/Action/ThreeDSecureAuthentication.pm',
    't/00-load.t',
    't/author-critic.t',
    't/author-eol.t',
    't/author-no-tabs.t',
    't/author-pod-coverage.t',
    't/author-pod-syntax.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
