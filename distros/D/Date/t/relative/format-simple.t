use 5.012;
use warnings;
use Test::More;
use lib 't/lib'; use MyTest;

catch_run("[relative-format-simple]");

my $fmt = Date::Rel::FORMAT_SIMPLE;

subtest 's' => sub {
    my $rel = new Date::Rel "6s";
    is($rel->sec, 6);
    is($rel->to_secs, 6);
    cmp_ok(abs($rel->to_mins - 0.1), '<', 0.000001);
    is $rel->to_string($fmt), "6s";
    is $rel->to_string($fmt), $rel->to_string;
};

subtest 'm' => sub {
    my $rel = new Date::Rel "5m";
    is($rel->min, 5);
    is($rel->to_secs, 300);
    is $rel->to_string($fmt), "5m";
};

subtest 'h' => sub {
    my $rel = new Date::Rel "2h";
    is($rel->hour, 2);
    is($rel->to_secs, 7200);
    is $rel->to_string($fmt), "2h";
};

subtest 'hms' => sub {
    my $rel = new Date::Rel "1s 1m 1h";
    is($rel->sec, 1);
    is($rel->min, 1);
    is($rel->hour, 1);
    is($rel->to_secs, 3661);
    is $rel->to_string($fmt), "1h 1m 1s";
};

subtest 'M' => sub {
    my $rel = new Date::Rel "-9999M";
    is($rel->month, -9999);
    is $rel->to_string($fmt), "-9999M";
};

subtest 'Y' => sub {
    my $rel = new Date::Rel "12Y";
    is($rel->year, 12);
    is $rel->to_string($fmt), "12Y";
};

subtest 'W' => sub {
    my $rel = new Date::Rel("2W");
    is $rel->day, 14;
    is $rel->to_string($fmt), "14D";
};

subtest 'YMDhms' => sub {
    my $rel = new Date::Rel("1Y 2M 3D 4h 5m 6s");
    is($rel->sec, 6);
    is($rel->min, 5);
    is($rel->hour, 4);
    is($rel->day, 3);
    is($rel->month, 2);
    is($rel->year, 1);
    is $rel->to_string($fmt), "1Y 2M 3D 4h 5m 6s";
};

subtest 'negative YMDhms' => sub {
    my $rel = new Date::Rel "-1Y 2M -3D -4h -5m -6s";
    is($rel->sec, -6);
    is($rel->min, -5);
    is($rel->hour, -4);
    is($rel->day, -3);
    is($rel->month, 2);
    is($rel->year, -1);
    is $rel->to_string($fmt), "-1Y 2M -3D -4h -5m -6s";
};

subtest 'not changed when bound to date' => sub {
    my $rel = rdate("1M");
    $rel->from(Date::now());
    is $rel->to_string($fmt), "1M";
};

done_testing();
