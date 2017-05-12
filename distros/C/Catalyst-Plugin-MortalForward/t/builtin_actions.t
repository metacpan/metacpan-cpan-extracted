#!perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More tests => 5;
use Catalyst::Test 'TestApp';

for (qw(/begin_dies /begin_dies_directly 
        /auto_dies /auto_dies_directly 
        /auto/auto/hello )) {
    my $res = request($_);

    is(
        $res->header('X-Test'),
        undef,
        'builtin action died correctly'
    );
}
