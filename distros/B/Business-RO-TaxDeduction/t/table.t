use strict;
use warnings;
use Test::Most;
use Scalar::Util qw(blessed);

use Business::RO::TaxDeduction::Table;

my $exepected = {
    0 => 510,
    1 => 670,
    2 => 830,
    3 => 990,
    4 => 1310,
    5 => 1310,
};

subtest 'Test for persons number range' => sub {
    foreach my $num ( 0 .. 5 ) {
        ok my $brtd = Business::RO::TaxDeduction::Table->new(
            year    => 2018,
            persons => $num,
            vbl     => 1950,
        ), "instance for $num person(s)";
        is $brtd->deduction, $exepected->{$num}, "deduction";
    }
};

done_testing;
