package Test::Class::Date::Holidays::Produceral;

use strict;
use warnings;
use base qw(Test::Class);
use Test::More;
use Date::Holidays::PRODUCERAL qw(holidays is_holiday);

my $day   = 24;
my $month = 12;
my $year  = 2007;


#run prior and once per suite
sub startup : Test(startup => 1) {
	diag("starting up...");
	
	use_ok('Date::Holidays');
}

sub test_produceral_interface : Test(13) {

	# bare

	use_ok('Date::Holidays::PRODUCERAL', qw(holidays is_holiday));

	can_ok('Date::Holidays::PRODUCERAL', qw(holidays is_holiday));

	ok(Date::Holidays::PRODUCERAL::holidays($year), 'calling holidays directly');

	is(Date::Holidays::PRODUCERAL::is_holiday($year, $month, $day), 'christmas', 'calling is_holiday directly');

	# wrapper

	ok(my $dh = Date::Holidays->new(nocheck => 1, countrycode => 'produceral'), 'instantiating Date::Holidays');
	isa_ok($dh, 'Date::Holidays', 'checking wrapper object');
	can_ok($dh, qw(holidays is_holiday));

	is($dh->is_holiday(year => $year, month => $month, day => $day), 'christmas', 'calling is_holiday via wrapper');

	ok(my $holidays = $dh->holidays(year => $year), 'calling holidays via wrapper');

	is(keys %{$holidays}, 1, 'we have one and only one holiday');

	is($holidays->{$month.$day}, 'christmas', 'christmas is present');

	#inner

	can_ok($dh->{'_inner_class'}, qw(holidays is_holiday));
	can_ok($dh->{'_inner_object'}, qw(holidays is_holiday));
}

1;
