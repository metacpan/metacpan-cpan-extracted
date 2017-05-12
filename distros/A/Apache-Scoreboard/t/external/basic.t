use strict;
use warnings FATAL => 'all';

use MyTest::Common ();
use Apache::Scoreboard ();
use APR::Pool ();

use Apache::Test;
use Apache::TestTrace;
use Apache::TestRequest ();

my $retrieve_url = MyTest::Common::retrieve_url();

my $pool = APR::Pool->new; #XXX: pool's life
my $ntests = MyTest::Common::num_of_tests();

plan todo => [], tests => $ntests, ['status'];

MyTest::Common::test1();

my $image = Apache::Scoreboard->fetch($pool, $retrieve_url);
MyTest::Common::test2($image);

1;

__END__
