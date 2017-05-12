use strict;
use warnings;

use Test::Most;

use constant MODULE => 'Bot::IRC::X::Feeds';

BEGIN { use_ok(MODULE); }

ok( MODULE->can('init'), 'init() method exists' );

done_testing;
