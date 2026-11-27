use strict;
use warnings;

use Test::More;
use Test::Needs;

# Date::Manip is not a dependency of Class::Shared.  It is large, and every site
# that uses it loads its own copy.  Date::Manip::Date also keeps a date between
# calls (parse a string, then ask for it in several formats), which is the part
# of its use that a shared backend has to preserve.  It is used when it is
# installed and skipped when it is not.
use Test::Needs { 'Date::Manip' => '6.00' };

use Class::Shared ();

BEGIN {
	test_needs 'Test::Permissions';

	plan skip_all => 'a backend needs unix sockets in an owner-only directory, '
		. 'which this perl cannot provide (Class::Shared is Unix-only)'
		unless Class::Shared::_has_unix_sockets()
			&& Test::Permissions::can_revoke_create();

	# Date::Manip stops to complain if it cannot tell which time zone it is in,
	# and the backend gets this environment from whoever starts it.  A fixed
	# zone also keeps the answers the same wherever the test runs.
	$ENV{TZ} = 'UTC';
}

use Date::Manip::Date ();
use File::Temp qw(tempdir);

use Class::Shared::Frontend;

my $dir = tempdir(CLEANUP => 1);

my $shared = Class::Shared::Frontend->new('Date::Manip::Date', dir => $dir);

# The same class, used here in this process.  Whatever it answers is what a
# frontend must answer: the backend adds no behaviour of its own.
my $direct = Date::Manip::Date->new;

is($shared->shared_status->{classes}[0], 'Date::Manip::Date', 'the backend loaded the class');

# --------------------------------------------- the same answers as the class

# Both are given the same calls, in the same order, so what is being compared is
# a date that was set by one call and read back by others.
{
	for my $string ('2026-12-25 14:30:00', '2024-02-29', '1999-12-31 23:59:59', '2038-01-19 03:14:08') {
		is($shared->parse($string), $direct->parse($string), "parse '$string': the same result");

		for my $format ('%Y-%m-%d %H:%M:%S', '%A', '%B %e, %Y', '%j', '%U') {
			is($shared->printf($format), $direct->printf($format),
				"  printf '$format': the same as calling the class directly");
		}

		is_deeply([$shared->value], [$direct->value], '  value: the same list of parts');
	}
}

# ------------------------------------------------- spot checks on the values

# These pin the answers, so that "the same as the class" is not "the same wrong answer".
{
	is($shared->parse('2026-12-25 14:30:00'), 0, 'parse returns 0 when it understood the date');
	is($shared->printf('%A, %d %B %Y'), 'Friday, 25 December 2026', 'the date is read back in another format');
	is($shared->printf('%H:%M'), '14:30', 'and the time');
	is_deeply([$shared->value], [2026, 12, 25, 14, 30, 0], 'value lists the parts');

	is($shared->parse('2024-02-29'), 0, 'a leap day is a date');
	is($shared->printf('%j'), '060', 'and is the 60th day of its year');
}

# ------------------------------------------------------------- a bad date

# The class reports a bad date as a non-zero return and keeps the reason, so
# both have to cross.  This is an error that is not an exception.
{
	my $result = $shared->parse('not a date at all');
	my $expected = $direct->parse('not a date at all');

	ok($result, 'parse returns true for a string it cannot understand');
	is($result, $expected, 'the same as the class');
	is($shared->err, $direct->err, 'and the reason is kept for the next call');
	like($shared->err, qr/Invalid date string/, 'and names the problem');
}

# -------------------------------------------------- state between the calls

# Each frontend has its own object, so each holds its own date.  Calls from the
# two are interleaved, to show that one does not change what the other holds.
{
	my $other = Class::Shared::Frontend->new('Date::Manip::Date', dir => $dir);

	$shared->parse('2026-12-25');
	$other->parse('2027-01-01');

	is($shared->printf('%Y-%m-%d'), '2026-12-25', 'a frontend keeps the date it was given');
	is($other->printf('%Y-%m-%d'), '2027-01-01', 'and another keeps its own');

	$shared->parse('2030-06-15');

	is($other->printf('%Y-%m-%d'), '2027-01-01', 'setting a date in one does not change the other');
	is($shared->shared_status->{objects}, 2, 'one object is held for each frontend');
	is($other->shared_pid, $shared->shared_pid, 'in the same backend');
}

# ---------------------------------------------- a list as an argument

# set takes an array reference, which crosses as a copy: that is plain data.
{
	$direct->set('date', [2026, 7, 4, 12, 0, 0]);
	$shared->set('date', [2026, 7, 4, 12, 0, 0]);

	is($shared->printf('%Y-%m-%d %H:%M:%S'), $direct->printf('%Y-%m-%d %H:%M:%S'),
		'a date set from an array reference is the same as the class gives');
	is($shared->printf('%A'), 'Saturday', 'and is a Saturday');
}

$shared->shared_shutdown;

ok(!-S $shared->shared_socket_path, 'the backend removed its socket on shutdown');

done_testing();
