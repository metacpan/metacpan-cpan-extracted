package TestInternal::basic;

use strict;
use warnings FATAL => 'all';

use Apache::Test;

use Apache2::Response ();
use Apache2::RequestRec ();

use Apache::Scoreboard ();
use MyTest::Common ();

use Apache2::Const -compile => 'OK';

sub handler {
    my $r = shift;

    my $ntests = MyTest::Common::num_of_tests();

    plan $r, todo => [], tests => $ntests, ['status'];

    MyTest::Common::test1();

    # get the image internally (only under the live server)
    my $image = Apache::Scoreboard->image($r->pool);
    MyTest::Common::test2($image);

    Apache2::Const::OK;
}

1;
