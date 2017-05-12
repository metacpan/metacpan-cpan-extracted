use lib qw'../lib lib t';
use TestConnector;
use DBIx::Struct (connector_module => 'TestConnector');
use Test::More;

use strict;
use warnings;

my %test_find = (
	findAll => "sub { DBIx::Struct::all_rows('table') }",
	findOnePeopleDistinctByLastnameAndFirstname =>
		"sub { DBIx::Struct::one_row(['table', -distinct => 'people'], -where => [-and => ['lastname' => \$_[1], 'firstname' => \$_[2]]]) }",
	findFirst1PeopleDistinctByLastnameAndFirstname =>
		"sub { DBIx::Struct::one_row(['table', -distinct => 'people'], -where => [-and => ['lastname' => \$_[1], 'firstname' => \$_[2]]]) }",
	findPeopleDistinctByLastnameAndFirstname =>
		"sub { DBIx::Struct::all_rows(['table', -distinct => 'people'], -where => [-and => ['lastname' => \$_[1], 'firstname' => \$_[2]]]) }",
	findDistinctnessDistinctByLastnameAndFirstname =>
		"sub { DBIx::Struct::all_rows(['table', -distinct => 'distinctness'], -where => [-and => ['lastname' => \$_[1], 'firstname' => \$_[2]]]) }",
	findFirst10DistinctPeopleByLastnameAndFirstname =>
		"sub { DBIx::Struct::all_rows(['table', -distinct => 'people'], -where => [-and => ['lastname' => \$_[1], 'firstname' => \$_[2]]], -limit => 10) }",
	findFirst10DistinctPeopleByAndyAndFirstname =>
		"sub { DBIx::Struct::all_rows(['table', -distinct => 'people'], -where => [-and => ['andy' => \$_[1], 'firstname' => \$_[2]]], -limit => 10) }",
	findByLastnameAndFirstname =>
		"sub { DBIx::Struct::all_rows('table', -where => [-and => ['lastname' => \$_[1], 'firstname' => \$_[2]]]) }",
	findByAddressZipCode           => "sub { DBIx::Struct::all_rows('table', -where => ['address_zip_code' => \$_[1]]) }",
	findByLastname                 => "sub { DBIx::Struct::all_rows('table', -where => ['lastname' => \$_[1]]) }",
	findFirstByOrderByLastnameAsc  => "sub { DBIx::Struct::one_row('table', -order_by => 'lastname') }",
	findFirstByOrderByLastnameDesc => "sub { DBIx::Struct::one_row('table', -order_by => {-desc => 'lastname'}) }",
	findFirst10ByOrderByLastnameAscFirstname =>
		"sub { DBIx::Struct::all_rows('table', -where => ['firstname' => \$_[1]], -order_by => 'lastname', -limit => 10) }",
	findFirst10ByFirstnameOrderByLastname =>
		"sub { DBIx::Struct::all_rows('table', -where => ['firstname' => \$_[1]], -order_by => 'lastname', -limit => 10) }",
	findFirst10ByLastname => "sub { DBIx::Struct::all_rows('table', -where => ['lastname' => \$_[1]], -limit => 10) }",
	findFirst10ByOrderByFirstnameAscLastname =>
		"sub { DBIx::Struct::all_rows('table', -where => ['lastname' => \$_[1]], -order_by => 'firstname', -limit => 10) }",
	findAllByCustomQueryAndStream =>
		"sub { DBIx::Struct::all_rows('table', -where => [-and => ['custom_query' => \$_[1], 'stream' => \$_[2]]]) }",
	findAllByStartDateLessThan => "sub { DBIx::Struct::all_rows('table', -where => ['start_date' => { '<' => \$_[1]}]) }",
	findAllByStartDateGreaterThanAndEndDateLessThanAndReferralIsNull =>
		"sub { DBIx::Struct::all_rows('table', -where => [-and => ['start_date' => { '>' => \$_[1]}, 'end_date' => { '<' => \$_[2]}, 'referral' => {'=', undef}]]) }",
	findOneName => "sub { DBIx::Struct::one_row(['table', -column => 'name']) }",
);

for my $test (keys %test_find) {
	is(DBIx::Struct::_parse_find_by("table", $test), $test_find{$test}, $test);
}

done_testing();
