# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl DateTime-LazyInit.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 107; #qw/no_plan/;#

use DateTime;
use DateTime::Duration;

my $have_exception;

BEGIN {
	use_ok('DateTime::LazyInit');
	eval("use Test::Exception");
	$have_exception = ($@) ? 0 : 1;
};

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $dtli = DateTime::LazyInit->new( year=>2006, month=>7, day=>25 );

isa_ok($dtli => 'DateTime::LazyInit');

# Check that an option not passed to the constructor is returning default
is( $dtli->hour => 0 );


foreach $attr (qw/year month day hour minute second nanosecond/) {

	my $setmethod = 'set_'.$attr;

	diag("Calling \$dtli->$setmethod") if $verbose;
	$dtli->$setmethod( 12 );

	isa_ok($dtli => 'DateTime::LazyInit');


	diag("Calling \$dtli->$attr") if $verbose;
	is( $dtli->$attr => 12 );

	isa_ok($dtli => 'DateTime::LazyInit');


	diag("Calling \$dtli->set($attr => 8)") if $verbose;
	$dtli->set( $attr => 8 );

	isa_ok($dtli => 'DateTime::LazyInit');


	diag("Calling \$dtli->$attr") if $verbose;
	is( $dtli->$attr => 8 );

	isa_ok($dtli => 'DateTime::LazyInit');

}




diag("Calling \$dtli->set_time_zone") if $verbose;
$dtli->set_time_zone( 'UTC' );

isa_ok($dtli => 'DateTime::LazyInit');



diag("Calling \$dtli->set_locale") if $verbose;
$dtli->set_locale( 'en_AU' );

isa_ok($dtli => 'DateTime::LazyInit');


diag("Calling \$dtli->clone") if $verbose;
my @dtli;
$dtli[0] = $dtli->clone;

isa_ok($dtli    => 'DateTime::LazyInit');
isa_ok($dtli[0] => 'DateTime::LazyInit');


# Make sure it really is a clone and not a ref

$dtli[0]->set( day => 1, month => 11 );

is($dtli->day   => 8);
is($dtli->month => 8);

is($dtli[0]->day   => 1 );
is($dtli[0]->month => 11);


# Get a few extra objects so we can inflate them one-by-one
for (0..2) {
	$dtli[$_] = $dtli->clone;
}

# Set an out-of-bounds value
$dtli[2]->set( day => 92 );
is($dtli[2]->day   => 92 );
isa_ok($dtli[2] => 'DateTime::LazyInit');


#----------------------------------------------------------------------
# Inflation Point
#----------------------------------------------------------------------


is ($dtli[0]->time_zone->name => 'UTC');

isa_ok($dtli[0] => 'DateTime');

# Make sure we didn't inflate the original object
isa_ok($dtli    => 'DateTime::LazyInit');

diag("Testing subtraction overload") if $verbose;
my $dtd = $dtli[0] - $dtli[1];

isa_ok($dtli[0] => 'DateTime');
isa_ok($dtli[1] => 'DateTime::LazyInit');
isa_ok($dtd     => 'DateTime::Duration');

SKIP: {
	skip "Can't load Test::Exception", 1 unless $have_exception;

	# $dtli[2] has an out-of-bounds day value so when
	# it inflates it should die

	dies_ok { $dtli[2]->add( months=>1 ) };
}


#----------------------------------------------------------------------
# Test other constructors
#----------------------------------------------------------------------

#
# from_epoch
#
my $time = time;
my $dtli_fe = DateTime::LazyInit->from_epoch(epoch => $time);
isa_ok($dtli_fe => 'DateTime::LazyInit');

is($dtli_fe->epoch, $time, "epoch accessor from from_epoch()");

# previous call to epoch() should have inflated
isa_ok($dtli_fe, 'DateTime');


#
# now
#
my $dtli_n = DateTime::LazyInit->now;
isa_ok($dtli_n => 'DateTime::LazyInit');

my $now_time = $dtli_n->epoch;
ok( ($now_time - $time) < 5, "epoch accessor from now()");

# previous call to epoch() should have inflated
isa_ok($dtli_n, 'DateTime');

#
# today
#
my $today = DateTime->today;
my $dtli_t = DateTime::LazyInit->today;
isa_ok($dtli_t => 'DateTime::LazyInit');

is( $dtli_t->datetime, $today->datetime, "datetime accessor from today()");

# previous call to datetime() should have inflated
isa_ok($dtli_t, 'DateTime');

#
# from_object
#
my $dtli_fo = DateTime::LazyInit->from_object( object => $today );
isa_ok($dtli_fo, 'DateTime::LazyInit');

is( $dtli_fo->datetime, $today->datetime,
    "datetime accessor from from_object()");

# previous call to datetime() should have inflated
isa_ok($dtli_fo, 'DateTime');

#
# last_day_of_month
#
my $dtli_ldom = DateTime::LazyInit->last_day_of_month(
    year => 2006, month => 1);

isa_ok($dtli_ldom, 'DateTime::LazyInit');

my $last_jan_day = DateTime->new(year => 2006, month => 1, day => 31);
$last_jan_day = $last_jan_day->truncate( to => 'day');

is( $dtli_ldom->datetime, $last_jan_day->datetime,
    "datetime accessor from last_day_of_month()" );

# previous call to datetime() should have inflated
isa_ok($dtli_ldom, 'DateTime');

#
# from_day_of_year
#
my $dtli_fdoy = DateTime::LazyInit->from_day_of_year(
    year => 2006, day_of_year => 1);
isa_ok($dtli_fdoy, 'DateTime::LazyInit');

my $first_jan_day = DateTime->new(year => 2006, month => 1, day => 1);
$first_jan_day = $first_jan_day->truncate( to => 'day' );

is($dtli_fdoy->datetime, $first_jan_day->datetime,
    "datetime accessor from first_day_of_year()" );

# previous call to datetime() should have inflated
isa_ok($dtli_fdoy, 'DateTime');



#----------------------------------------------------------------------
# Overloads
#----------------------------------------------------------------------

# <=> overload

my $dtli_over1 = DateTime::LazyInit->from_day_of_year(
    year => 2005, day_of_year => 1);
isa_ok($dtli_over1, 'DateTime::LazyInit');

my $dtli_over2 = DateTime::LazyInit->from_day_of_year(
    year => 2005, day_of_year => 5);
isa_ok($dtli_over2, 'DateTime::LazyInit');

ok($dtli_over1 < $dtli_over2,
    "Overload '<=>'" );

# previous call to datetime() should have inflated
isa_ok($dtli_over1, 'DateTime');
isa_ok($dtli_over2, 'DateTime');


# cmp overload

$dtli_over1 = DateTime::LazyInit->from_day_of_year(
    year => 2005, day_of_year => 1);
isa_ok($dtli_over1, 'DateTime::LazyInit');

$dtli_over2 = DateTime::LazyInit->from_day_of_year(
    year => 2005, day_of_year => 5);
isa_ok($dtli_over2, 'DateTime::LazyInit');

ok($dtli_over1 lt $dtli_over2,
    "Overload 'cmp'" );

# previous call to datetime() should have inflated
isa_ok($dtli_over1, 'DateTime');
isa_ok($dtli_over2, 'DateTime');


# string overload

$dtli_over1 = DateTime::LazyInit->from_day_of_year(
    year => 2005, day_of_year => 1);
isa_ok($dtli_over1, 'DateTime::LazyInit');

is("$dtli_over1", "2005-01-01T00:00:00",
    "Overload stringification" );

# previous call to datetime() should have inflated
isa_ok($dtli_over1, 'DateTime');


# subtract overload

$dtli_over1 = DateTime::LazyInit->from_day_of_year(
    year => 2005, day_of_year => 1);
isa_ok($dtli_over1, 'DateTime::LazyInit');

$dtli_over2 = DateTime::LazyInit->from_day_of_year(
    year => 2005, day_of_year => 5);
isa_ok($dtli_over2, 'DateTime::LazyInit');

isa_ok($dtli_over2 - $dtli_over1, 'DateTime::Duration',
    "Overload subtraction" );

# subtraction of DateTime::LazyInit should have inflated
isa_ok($dtli_over1, 'DateTime');
isa_ok($dtli_over2, 'DateTime');



$dtli_over2 = DateTime::LazyInit->from_day_of_year(
    year => 2005, day_of_year => 5);
isa_ok($dtli_over2, 'DateTime::LazyInit');

isa_ok($dtli_over2 - $dtli_over1, 'DateTime::Duration',
    "Overload subtraction" );

# subtraction of DateTime should have inflated
isa_ok($dtli_over2, 'DateTime');



$dtli_over2 = DateTime::LazyInit->from_day_of_year(
    year => 2005, day_of_year => 5);
isa_ok($dtli_over2, 'DateTime::LazyInit');

isa_ok($dtli_over2 - DateTime::Duration->new(days => 5), 'DateTime',
    "Overload subtraction" );

# subtraction of DateTime::Duration should have inflated
isa_ok($dtli_over2, 'DateTime');



# add overload

$dtli_over1 = DateTime::LazyInit->from_day_of_year(
    year => 2005, day_of_year => 1);
isa_ok($dtli_over1, 'DateTime::LazyInit');

isa_ok($dtli_over1 + DateTime::Duration->new(days => 5), 'DateTime',
    "Overload addition" );

# addition should have inflated
isa_ok($dtli_over1, 'DateTime');
