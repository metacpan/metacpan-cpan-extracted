use strict;
use warnings;
use Test::Most;
use Scalar::Util qw(blessed);

use Business::RO::TaxDeduction::Amount;

subtest 'Test for persons number range' => sub {
    foreach my $num ( 0 .. 4 ) {
        ok my $brtd = Business::RO::TaxDeduction::Amount->new(
            year    => 2016,
            persons => $num,
            ), "instance for $num person(s)";
        is $brtd->persons, $num, "$num persons";
    }
    foreach my $num ( 4 .. 10 ) {
        ok my $brtd = Business::RO::TaxDeduction::Amount->new(
            year    => 2016,
            persons => $num,
            ), "instance for $num person(s)";
        is $brtd->persons, 4, 'deduction for 4 persons';
    }
};

subtest 'Test for persons number range' => sub {
    ok my $ded = Business::RO::TaxDeduction::Amount->new(
        year    => 2010,
        ), 'new instance';
    is $ded->amount, 250, '2010 and 0 persons';

    ok $ded = Business::RO::TaxDeduction::Amount->new(
        persons => 0,
        year    => 2004,
        ), 'new instance';
    throws_ok { $ded->amount } qr/before 2005/,
        'should die for years before 2005';

    ok $ded = Business::RO::TaxDeduction::Amount->new(
        persons => 4,
        year    => 2015,
        ), 'new instance';
    is $ded->amount, 650, '2015 and 4 persons';

    ok $ded = Business::RO::TaxDeduction::Amount->new(
        persons => 0,
        ), 'new instance';
    is $ded->amount, 300, '2016 and 0 persons';

    ok $ded = Business::RO::TaxDeduction::Amount->new(
        persons => 4,
        ), 'new instance';
    is $ded->amount, 800, '2016 and 4 persons';

    ok $ded = Business::RO::TaxDeduction::Amount->new(
        persons => 5,
        ), 'new instance';
    is $ded->amount, 800, '2016 and 5 persons';
};

done_testing;
