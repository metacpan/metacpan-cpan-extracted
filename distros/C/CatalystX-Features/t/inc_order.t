use strict;
use warnings;
use Test::More;
use B::Deparse;
use FindBin;
use lib "$FindBin::Bin/lib/TestAppIncOrder/lib";

use Catalyst::Test 'TestAppIncOrder';

subtest 'features lib appears before app lib' => sub {
    my $c = TestAppIncOrder->new();

    my $resp = request('/');
    is $resp->content, 'overriden module';
};

done_testing;
