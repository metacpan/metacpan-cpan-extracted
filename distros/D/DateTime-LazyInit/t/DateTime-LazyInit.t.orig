# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl DateTime-LazyInit.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More qw/no_plan/;# tests => 'no_plan';

my $have_exception;

BEGIN {
	use_ok('DateTime::LazyInit');
	eval("use Test::Exception");
	$have_exception = ($@) ? 0 : 1;
};

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $dtli = DateTime::LazyInit->new( year=>2005, month=>7, day=>25 );

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
	dies_ok { $dtli[2]->add( months=>1 ) };
}






















