use 5.012;
use warnings;
use Test::More;
use Test::Exception;
use lib 't/lib'; use MyTest;

catch_run("[time-timegm]");

subtest "basic" => sub {
    my ($Y,$M,$D,$h,$m,$s) = (1970,234,-4643,2341,-34332,-1213213);
    is(timegm($s,$m,$h,$D,$M,$Y), 219167267);
    is_deeply([$Y,$M,$D,$h,$m,$s], [1970,234,-4643,2341,-34332,-1213213]);
};

subtest 'normalization' => sub {
    my ($Y,$M,$D,$h,$m,$s) = (2010,-123,-1234,12345,-123456,-1234567);
    is(timegmn($s,$m,$h,$D,$M,$Y), 867832073);
    is_deeply([$Y,$M,$D,$h,$m,$s], [1997,6,2,8,27,53]);
    
    dies_ok { timegmn(0,0,0,0,0,0) } 'read only values failure';
};

done_testing();