package Test::Class::Date::Holidays::Polymorphic;

use strict;
use warnings;
use base qw(Test::Class);
use Test::More;

our $VERSION = '1.29';

my $month = 12;
my $day   = 24;
my $year  = 2007;

#run prior and once per suite
sub startup : Test(startup => 2) {

    use_ok('Date::Holidays');
    use_ok('Date::Holidays::Polymorphic');

    return 1;
}

sub test_polymorphic_interface : Test(13) {

    # bare

    ok(my $polymorphic = Date::Holidays::Polymorphic->new());
    isa_ok($polymorphic, 'Date::Holidays::Polymorphic', 'checking OOP class object');
    can_ok($polymorphic, qw(new holidays is_holiday));

    ok($polymorphic->holidays());
    is($polymorphic->is_holiday(year => $year, month => $month, day => $day), 'christmas');

    # wrapper

    ok(my $dh = Date::Holidays->new(nocheck => 1, countrycode => 'Polymorphic'));
    isa_ok($dh, 'Date::Holidays', 'checking wrapper object');
    can_ok($dh, qw(new holidays is_holiday));

    is($dh->is_holiday(year => $year, month => $month, day => $day), 'christmas');
    ok(my $href = $dh->holidays(year => $year));
    is(ref $href, 'HASH');

    #inner

    isa_ok($dh->{_inner_object}, 'Date::Holidays::Adapter::Polymorphic', 'checking _inner_object');
    can_ok($dh->{_inner_object}, qw(new holidays is_holiday));
}

1;
