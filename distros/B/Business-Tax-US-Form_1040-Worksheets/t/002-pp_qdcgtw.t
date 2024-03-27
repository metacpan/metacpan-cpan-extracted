use 5.14.0;
use warnings;
use Test::More qw( no_plan );
use Carp;

use Business::Tax::US::Form_1040::Worksheets qw(
    qualified_dividends_capital_gains_tax
    pp_qdcgtw
);
#use Data::Dump qw(dd pp);

{
    my ($rv);
    my $first_arg = { foo => 'bar' };
    local $@;
    eval { $rv = pp_qdcgtw($first_arg); };
    like( $@, qr/First argument to pp_qdcgtw\(\) must be array reference/,
        "Got expected error message: bad first argument to pp_qdcgtw"
    );
}

##########

my $inputs = {
    l15 => 7000.00,
    l3a => 4900.00,
    sD  => 1600.00,
    status1 => 'single_or_married_sep',
    status2 => 'single',
    filing_year => 2023,
};
my $expect = {
    5 =>    500.00,
    18 =>   0,
    21 =>   0,
    1 =>    7000.00,
};
my $results = qualified_dividends_capital_gains_tax($inputs);
for my $j (18, 21, 1) {
    cmp_ok($results->[$j], '==', $expect->{$j},
    "Got expected result for line $j");
}
my $k = 5;
cmp_ok(abs($results->[$k] - $expect->{$k}), '<', 1,
    "Result for line $k, $results->[$k] is within expected tolerance from $expect->{$k}"
);

my $rv = pp_qdcgtw($results);
ok($rv, "pp_qdcgtw() returned true value");
