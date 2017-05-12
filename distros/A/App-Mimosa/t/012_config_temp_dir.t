use Test::Most tests => 1;
use strict;
use warnings;

BEGIN {
    $ENV{CATALYST_CONFIG_LOCAL_SUFFIX} = 'testing2';

}

use lib 't/lib';
use App::Mimosa::Test;

my (undef, $c) = ctx_request("/nowhere");
is($c->config->{tmp_dir}, "/tmp/blarg", "temp dir can be set in the config file");
