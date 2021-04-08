use 5.012;
use warnings;
use Test::More;
use lib 't/lib'; use MyTest;

catch_run("[time-timelocal]");

subtest "basic" => sub {
    is(timelocal(0, 20, 4, 21, 10, 2004), 1101000000); # standart time
    is(timelocal(20, 33, 23, 5, 5, 2005), 1118000000); # dst
    is(timelocal(2, 1, 0, 3, 6, 1916), -1688265017);
};

subtest "normalize" => sub {
    my ($isdst,$Y,$M,$D,$h,$m,$s) = (0,2005,2,27,2,30,0);
    is(timelocal($s,$m,$h,$D,$M,$Y,$isdst), 1111879800);
    is_deeply([$isdst,$Y,$M,$D,$h,$m,$s], [0,2005,2,27,2,30,0]);
    is(timelocaln($s,$m,$h,$D,$M,$Y,$isdst), 1111879800);
    is_deeply([$isdst,$Y,$M,$D,$h,$m,$s], [1,2005,2,27,3,30,0]);
    ($isdst,$Y,$M,$D,$h,$m,$s) = (0,2005,2,27,3,0,-1);
    is(timelocal($s,$m,$h,$D,$M,$Y,$isdst), 1111881599);
    is(timelocaln($s,$m,$h,$D,$M,$Y,$isdst), 1111881599);
    is_deeply([$isdst,$Y,$M,$D,$h,$m,$s], [1,2005,2,27,3,59,59]);
};

done_testing();
