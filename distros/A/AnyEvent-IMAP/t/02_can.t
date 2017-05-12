use strict;
use warnings;
use utf8;
use Test::More;

use AnyEvent::IMAP;

can_ok(AnyEvent::IMAP::, qw(new));

done_testing;

