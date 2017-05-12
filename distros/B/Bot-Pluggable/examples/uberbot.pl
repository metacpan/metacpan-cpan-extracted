# The uber-bot

use lib '../lib';
use Bot::Pluggable;
use UberBot::Joiner;
use UberBot::Factoid;
use UberBot::Seen;
use UberBot::Logger;
use POE;

my $factoid = UberBot::Factoid->new();
my $seen = UberBot::Seen->new();
my $logger = UberBot::Logger->new(FH => \*STDOUT);

my $bot = Bot::Pluggable->new(
        Modules => [qw(UberBot::Joiner)],
        Objects => [$seen, $factoid, $logger],
        Nick => 'uberbot',
        Server => 'grou.ch',
        Port => 6667,
        );

$poe_kernel->run();
exit(0);
