#!perl

use 5.010;
use strict;
use warnings;
use Test::More 0.98;

use Business::ID::VehiclePlate qw(parse_idn_vehicle_plate_number);
use Data::Clean::ForJSON;

test_parse(
    number => "d 1234 AAA",
    result => {
        prefix => 'D',
        ind_prefix_area => 'Bandung',
        prefix_iso_prov_codes => 'ID-JB',

        'ind_main_vehicle_type' => 'Kendaraan penumpang (1-1999)',
        main => '1234',

        suffix => 'AAA',

    },
);
test_parse(
    name   => 'invalid format',
    sim    => "1234 SJW",
    status => 400,
);

DONE_TESTING:
done_testing;

sub test_parse {
    my %args = @_;

    # just to convert DateTime object to Unix time
    #state $cleanser = Data::Clean::ForJSON->get_cleanser;

    subtest +($args{name} //= "number $args{number}"), sub {
        #my $res = $cleanser->clean_in_place(parse_sim(sim => $args{sim}));
        my $res = parse_idn_vehicle_plate_number(number => $args{number});

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
