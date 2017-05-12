use strict;
use warnings;

use Test::More;

use Config::Onion::Simple ':all';

isa_ok(cfg_obj, 'Config::Onion', 'cfg_obj returns a Config::Onion instance');
is_deeply(cfg, {}, 'cfg returns a hashref');

done_testing;

