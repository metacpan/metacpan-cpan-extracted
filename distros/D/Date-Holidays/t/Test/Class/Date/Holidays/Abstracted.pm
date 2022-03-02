package Test::Class::Date::Holidays::Abstracted;

use strict;
use warnings;
use base qw(Test::Class);
use Test::More;

our $VERSION = '1.29';

my $year = 2007;
my $month = 12;
my $day = 24;

#run prior and once per suite
sub startup : Test(startup => 1) {
    use_ok('Date::Holidays');
}

sub test_abstracted_implementation : Test(12) {
    SKIP: {
        eval { require Date::Holidays::Abstract };
        skip "Date::Holidays::Abstract not installed", 12 if $@;

        use_ok('Date::Holidays::Abstracted');

        ok(my $abstracted = Date::Holidays::Abstracted->new());
        isa_ok($abstracted, 'Date::Holidays::Abstracted', 'Testing object');
        can_ok($abstracted, qw(new holidays is_holiday));

        ok($abstracted->holidays($year), 'Testing holidays');
        is($abstracted->is_holiday($year, $month, $day), 'christmas','Testing christmas');

        ok(my $dh = Date::Holidays->new(nocheck => 1, countrycode => 'Abstracted'));
        isa_ok($dh, 'Date::Holidays', 'Testing object');
        can_ok($dh, qw(new holidays is_holiday));

        ok(my $href = $dh->holidays(year => $year), 'Testing holidays method');
        is(ref $href, 'HASH', 'Testing type of result from holidays method');
        is($dh->is_holiday(year => $year, month => $month, day => $day), 'christmas','Testing christmas');
    };
}

1;
