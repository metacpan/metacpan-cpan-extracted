use strict;
use warnings;

use Test::More;
use Test::Needs;
use Class::Shared ();

# The frontend reaches its backend over a unix socket in an owner-only
# directory.  The class it shares is a real module that has to be installed,
# and there is nothing to test without it.
#
# Both answers are worked out here, at compile time, before a test is output: a
# skip_all after tests have run is a plan for zero tests, which TAP reads as a
# bad plan, so no test ever added above a skip can be allowed to make one.
# Whether this perl can make the socket is asked of the module, and whether a
# directory here can really be made owner-only is asked of Test::Permissions,
# which tries chmod rather than guessing from the platform's name.
BEGIN {
	test_needs 'Test::Permissions';

	plan skip_all => 'a backend here is reached over a unix socket in an '
		. 'owner-only directory, which this perl cannot provide '
		. '(Class::Shared is Unix-only)'
		unless Class::Shared::_has_unix_sockets()
			&& Test::Permissions::can_revoke_create();

	test_needs 'Lingua::Conjunction';
}

use File::Temp qw(tempdir);
use lib 't/lib';

use Class::Shared::Frontend;

# Everything else in the suite shares Shared::Counter, which the backend has
# never heard of either, but this one shares a real module: the backend has to
# load Lingua::Conjunction from the installed tree and run its code.
my $dir = tempdir(CLEANUP => 1);

my $english = Class::Shared::Frontend->new(
	'Shared::Conjunction',
	ctor => [lang => 'en'],
	dir  => $dir,
);

END {
	eval { $english->shared_shutdown } if $english && $english->shared_connected;
}

isnt($english->shared_pid, $$, 'the object was constructed in another process');
is($english->module_version, $Lingua::Conjunction::VERSION,
	'and the backend loaded the real Lingua::Conjunction');
is($english->lang, 'en', 'with the arguments the frontend passed');

is($english->conjunction('Jack', 'Jill', 'Spot'), 'Jack, Jill, and Spot',
	'conjunction() runs in the shared copy');
is($english->conjunction('Jack', 'Jill'), 'Jack and Jill', 'and handles two items');
is($english->conjunction('Jack'), 'Jack', 'and one');

# Lingua::Conjunction keeps its language in package state, so a second object
# with a different language is the interesting case.
my $spanish = Class::Shared::Frontend->new(
	'Shared::Conjunction',
	ctor => [lang => 'es'],
	dir  => $dir,
);

is($spanish->conjunction('Jack', 'Jill', 'Spot'), 'Jack, Jill, y Spot',
	'a second object gets its own language');
is($english->conjunction('Jack', 'Jill', 'Spot'), 'Jack, Jill, and Spot',
	'and the first object is unaffected');
is($spanish->shared_pid, $english->shared_pid, 'both objects live in the one backend');

# The backend is not tied to one class: a frontend naming another one loads
# that module into the same process and gets its own objects from it.
my $counter = Class::Shared::Frontend->new(
	'Shared::Counter',
	ctor => [start => 7],
	dir  => $dir,
);

is($counter->shared_pid, $english->shared_pid,
	'a second class is served by the same backend');
is($counter->value, 7, 'with an object of its own');
is($english->conjunction('Jack', 'Jill'), 'Jack and Jill',
	'and the first class is unaffected');

my $status = `$^X -Ilib -It/lib bin/class-shared status --dir $dir 2>&1`;
like($status, qr/3 object\(s\)/, 'the backend counts all three objects') or diag $status;
like($status, qr/^classes: Shared::Conjunction, Shared::Counter$/m,
	'and lists both classes') or diag $status;

done_testing();
