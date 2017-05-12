######################################################################
# Test suite for Bot::WootOff
# by Mike Schilli <cpan@perlmeister.com>
######################################################################

use warnings;
use strict;

use Test::More;

plan tests => 4;

use Bot::WootOff;

my $bot = Bot::WootOff->new(spawn => 0);
is $bot->{irc_server}, "irc.freenode.net";
ok(1);

  # pseudo subclass
use Bot::Woot;
$bot = Bot::WootOff->new(spawn => 0);
is $bot->{irc_server}, "irc.freenode.net";
ok(1);
