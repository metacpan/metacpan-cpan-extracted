use 5.14.0;
use warnings;
use Test::More qw( no_plan );
use Carp;

use Business::Tax::US::Form_1040::Worksheets qw(
    social_security_worksheet_data
    pp_ssbw
    decimal_lines
);
#use Data::Dump qw(dd pp);

{
    my ($rv);
    my $first_arg = { foo => 'bar' };
    local $@;
    eval { $rv = pp_ssbw($first_arg); };
    like( $@, qr/First argument to pp_ssbw\(\) must be array reference/,
        "Got expected error message: bad first argument to pp_ssbw"
    );
}

my $inputs = {
    box5    => 33000.00,
    l1z     => 0,
    l2b     => 400.00,
    l3b     => 6200.00,
    l4b     => 0,
    l5b     => 8400.00,
    l7      => 1700.00,
    l8      => 1000.00,
    l2a     => 0,
    s1l11     => 0,
    s1l12     => 0,
    s1l13     => 0,
    s1l14     => 0,
    s1l15     => 0,
    s1l16     => 0,
    s1l17     => 0,
    s1l18     => 0,
    s1l19     => 0,
    s1l20     => 0,
    s1l23     => 0,
    s1l25     => 0,
    status     => 'single',
    filing_year => 2022,
};
my $expect = [
  undef,
  33000,    16500,  17700,  0,      34200,
  0,        34200,  25000,  9200,   9000,
  200,      9000,   4500,   4500,   170,
  4670,     28050, "4670.00",
];
my $formatted_expect = decimal_lines($expect);

my $worksheet_data = social_security_worksheet_data( $inputs );
is_deeply($worksheet_data, $formatted_expect,
    "Got expected social security worksheet data");

my $rv = pp_ssbw($worksheet_data);
ok($rv, "pp_ssbw() returned true value");

done_testing();
