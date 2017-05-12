use Test::Most tests => 1;
use strict;
use warnings;

use lib 't/lib';
use App::Mimosa::Test;

my (undef, $c) = ctx_request("/nowhere");
is($c->config->{default_mimosa_sequence_set_id}, 2, "can set a default sequence set");
