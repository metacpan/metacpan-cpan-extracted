use Test::Most 0.25;

# local test modules
use File::Spec;
use Cwd 'abs_path';
use File::Basename;
use lib File::Spec->catdir(dirname(abs_path($0)), 'lib');
use DateEasyTestUtil qw< is_true is_false >;


# There are several of these zonespec unit tests.  For purposes of reading the tests straight
# through, start with t/zonespec00.t and then proceed with the others in numerical order.


# on the other hand, if you do this:
use Date::Easy::Datetime 'GMT';

# then everything works the other way around:

my $t = Date::Easy::Datetime->new(1);
main::is_true $t->is_gmt, "change to GMT default via import";

{
	local $Date::Easy::Datetime::DEFAULT_ZONE = 'local';
	$t = Date::Easy::Datetime->new(1);
	main::is_true $t->is_local, "using block default (GMT import)";
}

$t = Date::Easy::Datetime->new(1);
main::is_true $t->is_gmt, "back to gmtime after block (GMT import)";


done_testing;
