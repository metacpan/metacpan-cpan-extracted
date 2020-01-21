use 5.012;
use warnings;
use Test::More;
use lib 't/lib'; use MyTest;

plan skip_all => 'Data::Recursive required for testing Data::Recursive::clone' unless eval { require Data::Recursive; 1 };

subtest 'date' => sub {
    my $a = date(1, 'GMT-1');
    my $b = Data::Recursive::clone($a);
    is $b->tzname, 'GMT-1';
    $a->truncate();
    is($a, '1970-01-01 00:00:00');
    is($b, '1970-01-01 01:00:01');
};

subtest 'rel without date' => sub {
    my $rel = rdate("1Y 2M 3D 4h 5m 6s");
    my $cl = Data::Recursive::clone($rel);
    $rel->year(2); $rel->month(3); $rel->day(4); $rel->hour(5); $rel->min(6); $rel->sec(7);
    is($rel, "2Y 3M 4D 5h 6m 7s");
    is($cl, "1Y 2M 3D 4h 5m 6s");
};

subtest 'rel with date' => sub {
    my $rel = rdate("2019-02-01", "2019-03-01");
    my $cl = Data::Recursive::clone($rel);
    $rel->year(1);
    is $rel.'', "1Y 1M";
    is $cl.'', "1M";
    is $cl->to_days, 28;
};

done_testing();
