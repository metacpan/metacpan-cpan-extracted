use strict;
use warnings;
use Test::More;
use Test::MockTime qw( :all );

use App::Monitor::Simple qw/run/;

# success
{
    my $ret = run(
        {
            command     => 'ping -c 1 yahoo.com',
            quiet       => 1,
        }
    );
    is($ret, 0, "return value is zero.");
}

# failure
{
    my $ret = run(
        {
            command     => 'ping -c 1 blahhhhhhhhhhhhhhhhh.jp',
            quiet       => 1,
        }
    );
    isnt($ret, 0, "return value isn't zero.");
}

# interval && retry
{
    set_absolute_time(0);
    my $st_time = time;
    my $ret = run(
        {
            command     => 'ping -c 1 blahhhhhhhhhhhhhhhhh.jp',
            interval    => 5,
            retry       => 2,
            quiet       => 1,
        }
    );
    my $ed_time = time;
    isnt($ret, 0, "return value isn't zero.");
    cmp_ok($ed_time, '>=', 10, 'interval && retry test (2 * 5)');
}

done_testing;
