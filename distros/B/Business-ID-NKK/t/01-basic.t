#!perl

use 5.010;
use strict;
use warnings;

use Business::ID::NKK qw(parse_nkk);
use Test::More 0.98;

test_parse(
    nkk    => "32 7300 010101 0001",
    status => 200,
    result => {
        'entry_date' => '2001-01-01',
        'loc_code' => '3273',
        'loc_ind_name' => 'BANDUNG',
        'loc_type' => '1',
        'prov_code' => '32',
        'prov_eng_name' => 'West Java',
        'prov_ind_name' => 'Jawa Barat',
        'serial' => '0001'
    },
);

test_parse(
    name   => "invalid date",
    nkk    => "32 7300 320180 0001",
    status => 400,
);

DONE_TESTING:
done_testing;

sub test_parse {
    my %args = @_;
    subtest +($args{name} //= "nkk $args{nkk}"), sub {
        my $res = parse_nkk(nkk => $args{nkk});
        if (exists $args{status}) {
            is($res->[0], $args{status}) or diag explain $res;
        }
        if (exists $args{result}) {
            is_deeply($res->[2], $args{result}) or diag explain $res;
        }
        if ($args{posttest}) {
            $args{posttest}->($res);
        }
    };
}
