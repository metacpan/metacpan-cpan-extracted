use strict;
use lib 't/lib';
use Config::Divide;
use t::Utils;
use Test::More;

my $test_pair = test_pair->{all};

for my $format (keys %$test_pair) {
    my ($main_dir, $sub_dir) = (
        "./t/config/$format/main",
        "./t/config/$format/sub"
    );

    my $data_type = $test_pair->{$format};
    my $got = Config::Divide->load_config(
        [$main_dir, $sub_dir],
    );
    my $expected = get_expected_data($data_type);

    is_deeply $got, $expected, "use arrayref";
}

done_testing;
