#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use Business::ID::NPWP qw(parse_npwp);

test_parse(
    npwp   => "02.183.241.5-000.000",
    status => 200,
    result => {
        'branch_code' => '000',
        'check_digit' => '5',
        'normalized' => '02.183.241.5-000.000',
        'serial' => 183241,
        'tax_office_code' => '000',
        'taxpayer_code' => '02',
    },
);

my @valid_npwps = qw(
02.183.241.5-000.000
02.061.179.4-000.000
01.957.716.2-000.000
02.808.957.1-000.000
02.183.787.7-000.000
01.749.700.9-000.000
01.132.928.1-000.000
01.002.720.9-000.000
01.233.075.9-000.000
01.000.724.3.000.000
001.000.724.3.000.000
);
for (@valid_npwps) {
    test_parse(npwp => $_, status => 200);
}

my @invalid_npwps = qw(
0
01.000.724.9.000.000
101.000.724.3.000.000
);
for (@invalid_npwps) {
    test_parse(npwp => $_, status => 400);
}

my @valid_niks = qw(
3273.0101.0190.0005
);
for (@valid_niks) {
    test_parse(npwp => $_, allow_nik => 1, status => 200);
}

my @invalid_niks = qw(
3273.0101.1390.0005
);
for (@invalid_niks) {
    test_parse(npwp => $_, allow_nik => 1, status => 400);
}

DONE_TESTING:
done_testing;

sub test_parse {
    my %args = @_;
    subtest +($args{name} //= "npwp $args{npwp}"), sub {
        my $res = parse_npwp(npwp => $args{npwp}, allow_nik => $args{allow_nik});
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
