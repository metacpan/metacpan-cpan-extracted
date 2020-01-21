use 5.012;
use warnings;
use Test::More;
use lib 't/lib'; use MyTest;

subtest 'from data' => sub {
    foreach my $file (map {"utc$_"} 1,2,3,4,5,6,7) {
        my $list = get_dates($file)->{UTC};
        foreach my $row (@$list) {
            my $result = join(',', Date::gmtime($row->[0]));
            is($result, join(',', @{$row->[1]}), 'gmtime: '.$row->[0]);
        }
    }
};

subtest64 'scalar context' => sub {
    like(scalar Date::gmtime(1387727619), qr/^\S+ \S+ 22 15:53:39 2013$/);
    
    is scalar(gmtime(+67767976233446399 + 1)), undef;
    is scalar(gmtime(-67768100567884800 - 1)), undef;
};

subtest64 'out of range' => sub {
    is_deeply [gmtime(+67767976233446399 + 1)], [];
    is_deeply [gmtime(-67768100567884800 - 1)], [];
};

done_testing();
