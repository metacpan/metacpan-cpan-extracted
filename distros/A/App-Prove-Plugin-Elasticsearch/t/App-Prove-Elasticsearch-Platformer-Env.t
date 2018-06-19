use strict;
use warnings;

use Test::More tests => 2;
use Test::Deep;
use Test::Fatal;
use App::Prove::Elasticsearch::Platformer::Env;

{
    local $ENV{'TESTSUITE_PLATFORM'} = 'Zippy OS 6,Perl v666';
    cmp_bag( App::Prove::Elasticsearch::Platformer::Env::get_platforms(),['Zippy OS 6','Perl v666'],"get_platforms returns expected information");
}

{
    local $ENV{'TESTSUITE_PLATFORM'} = '';
    like( exception { App::Prove::Elasticsearch::Platformer::Env::get_platforms() } ,qr/not set/i,"get_platforms explodes if TESTSUITE_PLATFORM is not set");
}
