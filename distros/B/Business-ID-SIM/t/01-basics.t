#!perl

use 5.010;
use strict;
use warnings;
use Test::More 0.98;

use Business::ID::SIM qw(parse_sim);
use Data::Clean::ForJSON;

test_parse(
    sim    => "0101 06 00 0001",
    result => {
        'area_code' => '0600',
        'dob' => 978307200,
        'prov_code' => '06',
        'serial' => 1,
    },
);
test_parse(
    name   => 'invalid month',
    sim    => "0113 40 00 0001",
    status => 400,
);
test_parse(
    name   => 'unknown province',
    sim    => "0113 99 00 0001",
    status => 400,
);

DONE_TESTING:
done_testing;

sub test_parse {
    my %args = @_;

    # just to convert DateTime object to Unix time
    state $cleanser = Data::Clean::ForJSON->get_cleanser;

    subtest +($args{name} //= "sim $args{sim}"), sub {
        my $res = $cleanser->clean_in_place(parse_sim(sim => $args{sim}));

        my $st = $args{status} // 200;
        is($res->[0], $st) or diag explain $res;

        if (exists $args{result}) {
            is_deeply($res->[2], $args{result}) or diag explain $res;
        }
        if ($args{posttest}) {
            $args{posttest}->($res);
        }
    };
}
