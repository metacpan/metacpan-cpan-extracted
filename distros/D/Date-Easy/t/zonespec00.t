use Test::Most 0.25;

# local test modules
use File::Spec;
use Cwd 'abs_path';
use File::Basename;
use lib File::Spec->catdir(dirname(abs_path($0)), 'lib');
use DateEasyTestUtil qw< is_true is_false >;


# There are several of these zonespec unit tests.  We have to put them in different files because
# some of them twiddle the global variable that controls the default zonespec, so they would step on
# each other if they were in the same file.  For purposes of reading the tests straight through,
# start with this file and then proceed with the others in numerical order.

# This first file also tests the working of the boolean methods `is_local`, `is_gmt`, and `is_utc`.
# The other zonespec test files just assume that if one of them is correct, the others will be as
# well.


use Date::Easy::Datetime;

# default is local
my $t = Date::Easy::Datetime->new(1);
main::is_true  $t->is_local, "datetime defaults to localtime (is local)";
main::is_false $t->is_gmt,   "datetime defaults to localtime (not gmt)";

# but you can change things locally
{
	local $Date::Easy::Datetime::DEFAULT_ZONE = 'GMT';
	$t = Date::Easy::Datetime->new(1);
	main::is_false $t->is_local, "using block default (is local)";
	main::is_true  $t->is_gmt,   "using block default (not gmt)";
}

# should go back to local here
$t = Date::Easy::Datetime->new(1);
main::is_true  $t->is_local, "back to localtime after block (is local)";
main::is_false $t->is_gmt,   "back to localtime after block (not gmt)";


# (while we're here, make sure that `is_utc` is an alias for `is_gmt`)

# comparing function pointers as strings verifies that they have the same memory address
is \&Date::Easy::Datetime::is_utc, \&Date::Easy::Datetime::is_gmt, "is_utc is alias for is_gmt";


done_testing;
