use Test::Most 0.25;

use Date::Easy;

# local test modules
use File::Spec;
use Cwd 'abs_path';
use File::Basename;
use lib File::Spec->catdir(dirname(abs_path($0)), 'lib');
use DateEasyTestUtil qw< compare_times generate_times_and_compare >;


my $t;
lives_ok { $t = Date::Easy::Datetime->new } "basic ctor call";
isa_ok $t, 'Date::Easy::Datetime', 'ctor with no args';

# We're testing equivalence between 3 things.  But because we must use our special test function
# which helps us avoid failures due to timing issues, we can only test two at a time.  So we'll test
# the first and second, then test the first and third, then we'll trust the transitive laws of
# mathematics to believe that the second and the third are also equivalent.

generate_times_and_compare { Date::Easy::Datetime->new, now           } "default ctor matches now function";
generate_times_and_compare { Date::Easy::Datetime->new, local => time } "default ctor matches return from time()";


# with 6 args, ctor should just build that date

my $FMT = '%Y%m%d%H%M%S';
my @SEXTUPLE_ARGS = qw< 19940203103223 20010905134816 19980908170139 19691231235959 20360229000000 >;
foreach (@SEXTUPLE_ARGS)
{
	my @args = /^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})$/;
	s/^0// foreach @args;							# more natural, and avoids any chance of octal number errors
	$t = Date::Easy::Datetime->new(@args);
	is $t->strftime($FMT), $_, "successfully constructed (6args): $_";
}


# 1 arg should be treated as epoch seconds

foreach ("12/31/2009", "2/29/2000 2:28:09PM",
		"10/14/1066 09:00:00 GMT", "10/26/1881 15:00:00 MST", "3/31/1918 03:00:00 EDT")
{
	use Time::ParseDate;
	my $t = parsedate($_);
	isnt $t, undef, "sanity check: can parse $_";

	my $dt = Date::Easy::Datetime->new($t);
	compare_times($dt, local => $t, "successfully constructed (1arg): $_");
}


# 2 args is a zone specifier and epoch seconds

foreach ("12/31/2009", "2/29/2000 2:28:09PM",
		"10/14/1066 09:00:00 GMT", "10/26/1881 15:00:00 MST", "3/31/1918 03:00:00 EDT")
{
	use Time::ParseDate;
	my $t = parsedate($_, GMT => 1);
	isnt $t, undef, "sanity check: can parse $_ (GMT)";

	compare_times(Date::Easy::Datetime->new(UTC => $t), UTC => $t, "successfully constructed (2arg UTC): $_");
	compare_times(Date::Easy::Datetime->new(GMT => $t), GMT => $t, "successfully constructed (2arg GMT): $_");
	compare_times(Date::Easy::Datetime->new(local => $t), local => $t, "successfully constructed (2arg local): $_");
}


# 7 args is a zone specifier and year/month/day/hours/minutes/seconds

foreach (@SEXTUPLE_ARGS)
{
	use Date::Parse;
	my @args = /^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})$/;
	s/^0// foreach @args;							# more natural, and avoids any chance of octal number errors
	foreach my $l (qw< local GMT UTC >)
	{
		my @extra_args = $l eq 'local' ? () : (GMT => 1);
		my $secs = str2time(join(' ', join('/', @args[0,1,2]), join(':', @args[3,4,5])), @extra_args);
		isnt $secs, undef, "sanity check: can parse $_ ($l)";

		compare_times(Date::Easy::Datetime->new($l => @args), $l => $secs, "successfully constructed (7args $l): $_");
	}
}


# make sure we return a proper object even in list context
my @t = Date::Easy::Datetime->new;
is scalar @t, 1, 'ctor not returning multiple values in list context';
isa_ok $t[0], 'Date::Easy::Datetime', 'ctor in list context';


done_testing;
