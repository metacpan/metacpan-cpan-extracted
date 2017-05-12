use strict;
use warnings;
use Test::More;
use B::Deparse;

use FindBin;
use lib "$FindBin::Bin/lib/TestAppMason/lib";

eval { require Catalyst::View::Mason };
plan skip_all => "View::Mason not installed" if $@; 

plan tests => 2;
use_ok 'Catalyst::Test', 'TestApp';

{

    my $resp = request('/test/mason');
    is($resp->content, 'mason running', 'feature mason template');
}

done_testing;

