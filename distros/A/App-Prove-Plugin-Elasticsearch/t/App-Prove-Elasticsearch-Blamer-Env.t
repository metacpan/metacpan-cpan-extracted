use strict;
use warnings;

use Test::More tests => 2;
use Test::Fatal;
use App::Prove::Elasticsearch::Blamer::Env;

{
    local $ENV{TESTSUITE_EXECUTOR} = 'zippy';
    is(App::Prove::Elasticsearch::Blamer::Env::get_responsible_party(),'zippy',"get_responsible_party returns correct author passed in ENV");
}

{
    local $ENV{TESTSUITE_EXECUTOR} = '';
    like(exception { App::Prove::Elasticsearch::Blamer::Env::get_responsible_party() },qr/not set/i,"get_responsible_party explodes when ENV is not set");
}
