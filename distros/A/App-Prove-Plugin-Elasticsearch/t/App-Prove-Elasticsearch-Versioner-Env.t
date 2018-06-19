use strict;
use warnings;

use Test::More tests => 2;
use Test::Fatal;
use App::Prove::Elasticsearch::Versioner::Env;

{
    local $ENV{TESTSUITE_VERSION} = '666';
    is(App::Prove::Elasticsearch::Versioner::Env::get_version(),'666',"get_version returns correct version in TESTSUITE_VERSION");
}

{
    local $ENV{TESTSUITE_VERSION} = '';
    like(exception { App::Prove::Elasticsearch::Versioner::Env::get_version() },qr/not set/i,"get_version dies on no TESTSUITE_VERSION");
}
