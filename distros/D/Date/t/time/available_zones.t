use 5.012;
use warnings;
use Test::More;
use Test::Deep;
use lib 't/lib'; use MyTest;

subtest 'embed' => sub {
    my @zones = Date::available_zones();
    my $cnt = @zones;
    is($cnt, 1212);
};

subtest 'system' => sub {
    plan skip_all => "set TEST_FULL" unless $ENV{TEST_FULL};
    Date::use_system_zones();
    my @zones = Date::available_zones();
    cmp_ok scalar(@zones), '>', 0;
};

done_testing();
