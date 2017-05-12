use strict;
use warnings;
use utf8;
use Test::More;

use App::KV2JSON;
is(App::KV2JSON->run(qw/var=1/), '{"var":"1"}'."\n");
is(App::KV2JSON->run(qw/var#=1/), '{"var":1}'."\n");

done_testing;
