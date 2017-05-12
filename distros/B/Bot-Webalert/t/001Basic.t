######################################################################
# Test suite for Bot::Webalert
# by Mike Schilli <cpan@perlmeister.com>
######################################################################

use warnings;
use strict;

use Test::More;
use Bot::Webalert;
use HTTP::Request::Common;
use POE::Kernel;

plan tests => 2;

eval { my $bot = Bot::Webalert->new(); };

like $@, qr/Missing mandatory parameters/, "parameter check";

my $bot = Bot::Webalert->new(
	server   => 'irc.freenode.net',
	channels => ["#friends_of_webalert"],
	ua_request  => GET("http://www.yahoo.com"),
);

is ref($bot), "Bot::Webalert", "constructor ok";

close STDERR; # Otherwise POE sends this stupid warning that we haven't
              # run the kernel
