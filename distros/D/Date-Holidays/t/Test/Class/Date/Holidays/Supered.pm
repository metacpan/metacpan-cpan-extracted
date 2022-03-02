package Test::Class::Date::Holidays::Supered;

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

sub test_supered_implementation : Test(12) {

    SKIP: {
        eval { require Date::Holidays::Super };
        skip "Date::Holidays::Super not installed", 12 if $@;

        use_ok('Date::Holidays::Supered');

        ok(my $supered = Date::Holidays::Supered->new());
        isa_ok($supered, 'Date::Holidays::Supered');
        can_ok($supered, qw(new holidays is_holiday));

        ok($supered->holidays($year), 'Testing holidays');
        is($supered->is_holiday($year, $month, $day), 'christmas','Testing christmas');

        ok(my $dh = Date::Holidays->new(nocheck => 1, countrycode => 'Supered'), 'Testing adaptability via Date::Holidays');
        isa_ok($dh, 'Date::Holidays');
        can_ok($dh, qw(new holidays is_holiday));

        ok(my $href = $dh->holidays(year => $year), 'Testing holidays method');
        is(ref $href, 'HASH', 'Testing type of result from holidays method');
        is($dh->is_holiday(year => $year, month => $month, day => $day), 'christmas', 'Testing is_holiday method');
    };
}

1;
