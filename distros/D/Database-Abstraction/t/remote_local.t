# Tests for the local-host short-circuit in Database::Abstraction.
#
# When host => 'localhost', '127.0.0.1', '::1', or the current machine's
# hostname is given, _open() must read the directory directly without invoking
# File::Slurp::Remote at all.  This file does NOT require File::Slurp::Remote
# to be installed — the test exercises the fallback path that avoids it.

use strict;
use warnings;

use File::Spec;
use File::Temp qw(tempdir);
use Sys::Hostname qw(hostname);
use Test::Most;

BEGIN {
	package Database::localtest;
	use base 'Database::Abstraction';
}

# ---------------------------------------------------------------------------
# Fixture: a small CSV file in a real local temp directory
# ---------------------------------------------------------------------------

my $dir = tempdir(CLEANUP => 1);
my $csv = File::Spec->catfile($dir, 'localtest.csv');
open my $fh, '>', $csv;
print $fh "entry!name!score\none!Alice!10\ntwo!Bob!20\nthree!Carol!30\n";
close $fh;

# ---------------------------------------------------------------------------
# Helper: build an object and assert SSH is never invoked
# If File::Slurp::Remote happens to be installed (e.g. the full test suite
# ran first), override read_remote_file to die so we detect any mistake.
# ---------------------------------------------------------------------------

sub make_dao {
	my %args = @_;

	# If the module is already loaded, install a sentinel that fails the test.
	if(exists $INC{'File/Slurp/Remote.pm'}) {
		no warnings 'redefine';
		*File::Slurp::Remote::read_remote_file = sub {
			fail("read_remote_file called for a local host — SSH must not be used");
			die 'sentinel: should not be reached';
		};
	}

	return Database::localtest->new(directory => $dir, %args);
}

# ---------------------------------------------------------------------------
# Section 1: _is_local_host() white-box tests
# ---------------------------------------------------------------------------

my $probe = Database::localtest->new(directory => $dir);

ok( $probe->_is_local_host('localhost'),   '_is_local_host: localhost');
ok( $probe->_is_local_host('127.0.0.1'),   '_is_local_host: 127.0.0.1');
ok( $probe->_is_local_host('::1'),         '_is_local_host: ::1');

my $me = hostname();
ok( $probe->_is_local_host($me),           "_is_local_host: own hostname ($me)");

# user@local forms
ok( $probe->_is_local_host("user\@localhost"),  '_is_local_host: user@localhost');
ok( $probe->_is_local_host("njh\@127.0.0.1"),   '_is_local_host: user@127.0.0.1');
ok( $probe->_is_local_host("me\@$me"),           "_is_local_host: user\@$me");

# short-name match (strip domain from whichever side has one)
(my $me_short = $me) =~ s/\..*//;
ok( $probe->_is_local_host($me_short),     "_is_local_host: short hostname ($me_short)");

ok(!$probe->_is_local_host('remoteserver'),      '_is_local_host: remote name returns false');
ok(!$probe->_is_local_host('db.example.com'),    '_is_local_host: remote FQDN returns false');
ok(!$probe->_is_local_host('192.168.1.1'),       '_is_local_host: non-loopback IP returns false');

# ---------------------------------------------------------------------------
# Section 2: host => 'localhost' reads local files without SSH
# ---------------------------------------------------------------------------

my $dao_local = make_dao(host => 'localhost');
my $all = $dao_local->selectall_arrayref();
is(ref($all), 'ARRAY', 'host=localhost: selectall_arrayref returns arrayref');
is(scalar @{$all}, 3,  'host=localhost: 3 rows returned');

my %by_entry = map { $_->{'entry'} => $_ } @{$all};
is($by_entry{'one'}{'name'},   'Alice', 'host=localhost: row one name');
is($by_entry{'two'}{'score'},  20,      'host=localhost: row two score');
is($by_entry{'three'}{'name'},'Carol',  'host=localhost: row three name');

is($dao_local->count(), 3, 'host=localhost: count() = 3');
is($dao_local->fetchrow_hashref(entry => 'two')->{'name'}, 'Bob',
	'host=localhost: fetchrow_hashref');

# ---------------------------------------------------------------------------
# Section 3: host => '127.0.0.1' reads local files without SSH
# ---------------------------------------------------------------------------

my $dao_127 = make_dao(host => '127.0.0.1');
is(scalar @{$dao_127->selectall_arrayref()}, 3, 'host=127.0.0.1: 3 rows');

# ---------------------------------------------------------------------------
# Section 4: host => '::1' (IPv6 loopback) reads local files without SSH
# ---------------------------------------------------------------------------

my $dao_ipv6 = make_dao(host => '::1');
is(scalar @{$dao_ipv6->selectall_arrayref()}, 3, 'host=::1: 3 rows');

# ---------------------------------------------------------------------------
# Section 5: host => $hostname (current machine name) reads local files
# ---------------------------------------------------------------------------

my $dao_me = make_dao(host => $me);
is(scalar @{$dao_me->selectall_arrayref()}, 3, "host=$me: 3 rows");

# Short hostname
my $dao_short = make_dao(host => $me_short);
is(scalar @{$dao_short->selectall_arrayref()}, 3, "host=$me_short: 3 rows");

# user@localhost form
my $dao_user = make_dao(host => "user\@localhost");
is(scalar @{$dao_user->selectall_arrayref()}, 3, 'host=user@localhost: 3 rows');

# ---------------------------------------------------------------------------
# Section 6: no _remote_tmpdir created for local hosts
# ---------------------------------------------------------------------------

my $dao_check = make_dao(host => 'localhost');
$dao_check->selectall_arrayref();	# trigger _open
ok(!exists($dao_check->{'_remote_tmpdir'}),
	'host=localhost: _remote_tmpdir not created (no temp dir needed)');

done_testing();
