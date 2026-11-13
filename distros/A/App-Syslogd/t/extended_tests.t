#!/usr/bin/env perl

# Extended tests: the execution paths the other test files leave untried.
#
# Strategy
#	Devel::Cover run over the whole suite showed seven gaps in branch and
#	condition coverage, and every one is a guard that the normal flow
#	never reaches.  Each is reached here on purpose:
#
#	* App::Syslogd::Cache: a queue item left behind by a replaced entry
#	  (serial mismatch), one left behind by an entry that was dropped
#	  for being too big (key gone), and an empty queue when the byte
#	  count says there is something to evict.  The clock is replaced
#	  (mock_core) so expiry is exact and nothing sleeps.
#	* App::Syslogd::new: the cache constructor gives back nothing.
#	* App::Syslogd::run: the socket is missing when the log fails to open.
#	* App::Syslogd::I18N::handle: even the fallback language is missing.
#	* App::Syslogd (load time): a warning from a dependency passes
#	  through the CHECK-block filter, in a child process.
#
#	Not reachable by any test (see the end of this file):
#	the "// $DEFAULT_MAX_BYTES" default in App::Syslogd::Cache::new.
#
#	The tests describe what the POD promises, not what the code does.
#	Set TEST_VERBOSE=1 to see the internal state behind each check.

use strict;
use warnings;

use File::Spec;
use File::Temp qw(tempdir);
use FindBin qw($Bin);
use IPC::Open3 qw(open3);
use Readonly;
use Test::Memory::Cycle;
use Test::Mockingbird;
use Test::Most;
use Test::Returns;

# A clock the tests move by hand, set before the cache is compiled
our $NOW = 1_000_000;
BEGIN { mock_core('time' => sub { return $main::NOW }) }

use lib "$Bin/../lib";
use App::Syslogd;
use App::Syslogd::Cache;
use App::Syslogd::I18N;

# White-box access to the :Private helpers
$Sub::Private::BYPASS = $Sub::Protected::BYPASS = 1;

# Every literal the tests depend on, named once
Readonly my %CONFIG => (
	overhead => 64,			# the documented cost of each entry
	ttl => 10,			# seconds an entry lives
	value => 'x',			# a one-character value
	replaced_value => 'y',
	slots => 3,			# entries the small cache holds
	fallback_language => 'en',
	other_language => 'fr',
	oversize_extra => 200,		# makes a value too big for the small cache
	sentinel => 'sentinel: a warning from a dependency',
	late_check => 'Too late to run CHECK block',
	start_error => "boom\n",
);

# The documented cost of one entry
sub size_of { my ($key, $value) = @_; return length($key) + length($value) + $CONFIG{overhead} }

# A cache that holds exactly $CONFIG{slots} entries made from one-character
# keys and values
sub small_cache {
	my $size = size_of('a', $CONFIG{value});
	return App::Syslogd::Cache->new(max_bytes => $CONFIG{slots} * $size);
}

# compute() with a fixed value
sub put {
	my ($cache, $key, $value) = @_;
	return $cache->compute($key, $CONFIG{ttl}, sub { return $value });
}

# Show the state of a cache, but only when asked
sub show_cache {
	my ($label, $cache) = @_;
	return unless($ENV{TEST_VERBOSE});
	diag("$label: bytes=$cache->{bytes} entries=" . join(',', sort keys %{$cache->{entries}})
		. ' queue=' . join(',', map { "$_->[0]#$_->[1]" } @{$cache->{order}}));
	return;
}

# A scratch directory for files, removed at exit
my $dir = tempdir(CLEANUP => 1);
my $serial = 0;
sub new_path { return File::Spec->catfile($dir, 'log' . ++$serial . '.csv') }

# ===========================================================================
# App::Syslogd::Cache::compute: leftovers in the age queue
# ===========================================================================

subtest 'cache: a queue item for a replaced entry is skipped (serial mismatch)' => sub {
	# Purpose: when an expired key is computed again, its old queue item
	# stays in the queue with the old serial.  Making room must drop that
	# item without evicting the live entry that has the same key.
	local $NOW = 1_000_000;
	my $cache = small_cache();

	put($cache, 'a', $CONFIG{value});
	$NOW += $CONFIG{ttl};		# 'a' is now exactly expired
	is(put($cache, 'a', $CONFIG{replaced_value}), $CONFIG{replaced_value}, "'a' is computed again");
	put($cache, 'b', $CONFIG{value});
	put($cache, 'c', $CONFIG{value});
	show_cache('before the fourth key', $cache);
	is(scalar(@{$cache->{order}}), 4, 'the queue holds the stale item as well as three live ones');

	put($cache, 'd', $CONFIG{value});
	show_cache('after the fourth key', $cache);

	is_deeply([sort keys %{$cache->{entries}}], [qw(b c d)], 'the oldest live entry went; the others stayed');
	is($cache->{bytes}, $CONFIG{slots} * size_of('a', $CONFIG{value}), 'the byte count is exact');
	returns_ok($cache->compute('b', $CONFIG{ttl}, sub { die 'must not be called' }), { type => 'string' }, "'b' is still remembered");
	memory_cycle_ok($cache, 'no reference cycle');
};

subtest 'cache: a queue item whose entry is gone is skipped (key missing)' => sub {
	# Purpose: an expired entry is forgotten before its replacement is
	# charged for.  If the replacement is too big to keep, nothing is
	# stored, and the old queue item points at a key that no longer exists.
	# Making room must step over it.
	local $NOW = 2_000_000;
	my $cache = small_cache();

	put($cache, 'a', $CONFIG{value});
	$NOW += $CONFIG{ttl};
	my $big = 'z' x $CONFIG{oversize_extra};
	is(put($cache, 'a', $big), $big, 'a value too big to keep is still returned');
	ok(!exists($cache->{entries}{a}), 'and nothing is remembered for the key');
	is($cache->{bytes}, 0, 'no bytes are charged');
	is(scalar(@{$cache->{order}}), 1, 'the old queue item is still there');

	put($cache, $_, $CONFIG{value}) foreach(qw(b c d));	# fills the cache
	show_cache('full', $cache);
	put($cache, 'e', $CONFIG{value});			# forces the clean-up
	show_cache('after the fifth key', $cache);

	is_deeply([sort keys %{$cache->{entries}}], [qw(c d e)], 'the stale item was dropped, then the oldest live entry');
	is($cache->{bytes}, $CONFIG{slots} * size_of('a', $CONFIG{value}), 'the byte count is exact');
	memory_cycle_ok($cache, 'no reference cycle');
};

subtest 'cache: nothing is left to evict' => sub {
	# Purpose: the loop that makes room stops when the queue is empty,
	# even if the byte count says the cache is full, so it can never spin
	# or die.  The count is damaged by hand to reach this guard.
	local $NOW = 3_000_000;
	my $cache = small_cache();
	$cache->{bytes} = $cache->{max_bytes};
	show_cache('damaged', $cache);

	my $value;
	lives_ok { $value = put($cache, 'k', $CONFIG{value}) } 'compute() ends';
	is($value, $CONFIG{value}, 'and returns the value');
	ok(exists($cache->{entries}{k}), 'the entry is remembered');
	is(scalar(@{$cache->{order}}), 1, 'and queued once');
};

# ===========================================================================
# App::Syslogd::new: the cache constructor gives back nothing
# ===========================================================================

subtest 'new: a cache constructor that returns nothing does not stop construction' => sub {
	# Purpose: new() makes a cache only if none was passed in.  It does
	# not check what the cache class returns, so a subclass or a mock
	# that returns nothing must not make new() fail.
	my $calls = 0;
	my $guard = mock_scoped('App::Syslogd::Cache::new' => sub { $calls++; return 0 });

	my $server;
	lives_ok { $server = App::Syslogd->new(file => new_path(), resolve => 0) } 'new() lives';
	is($calls, 1, 'the cache constructor was asked once');
	returns_ok($server, { type => 'object', isa => 'App::Syslogd' }, 'and the result is a server');
	ok(!$server->{cache}, 'the server has no usable cache');
	diag('cache slot: ' . ($server->{cache} // 'undef')) if($ENV{TEST_VERBOSE});
};

# ===========================================================================
# App::Syslogd::run: all or nothing, with no socket to close
# ===========================================================================

subtest 'run: a failed start with no socket still reports the open error' => sub {
	# Purpose: run() closes a socket it opened itself when the log will
	# not open.  If there is no socket to close, the original error must
	# still reach the caller, unchanged.
	my $server = App::Syslogd->new(file => new_path(), resolve => 0);
	my $opened = 0;
	my $guards = [
		mock_scoped('App::Syslogd::open_socket' => sub { $opened++; return $_[0] }),
		mock_scoped('App::Syslogd::reopen_log' => sub { die $CONFIG{start_error} }),
	];

	throws_ok { $server->run() } qr/\A\Q$CONFIG{start_error}\E\z/, 'the open error is rethrown as it was';
	is($opened, 1, 'open_socket() was tried once');
	ok(!$server->{socket}, 'no socket is left');
	ok(!$server->{running}, 'the server is not marked as running');
	memory_cycle_ok($server, 'no reference cycle');
};

# ===========================================================================
# App::Syslogd::I18N::handle: even the fallback is missing
# ===========================================================================

subtest 'i18n: handle() gives back nothing when no lexicon loads' => sub {
	# Purpose: handle() asks for the wanted language, then for the
	# fallback.  If both fail it has nothing to return, and says so with
	# undef rather than dying.
	my @asked;
	my $guard = mock_scoped('App::Syslogd::I18N::get_handle' => sub {
		my ($class, @tags) = @_;
		push @asked, [@tags];
		return undef;
	});

	is(App::Syslogd::I18N->handle($CONFIG{other_language}), undef, 'a wanted language and no fallback: undef');
	is_deeply(\@asked, [[$CONFIG{other_language}], [$CONFIG{fallback_language}]], 'asked for the language, then for the fallback');

	@asked = ();
	is(App::Syslogd::I18N->handle(undef), undef, 'no wanted language and no fallback: undef');
	is_deeply(\@asked, [[], [$CONFIG{fallback_language}]], 'asked for the default, then for the fallback');
	diag('asked: ' . scalar(@asked) . ' times in the last call') if($ENV{TEST_VERBOSE});
};

subtest 'i18n: handle() returns a handle when the wanted language is missing' => sub {
	# Purpose: the other side of the same guard, with the real class: an
	# unknown language falls back to the fallback language
	my $handle = App::Syslogd::I18N->handle('xx-unknown');
	returns_ok($handle, { type => 'object', isa => 'App::Syslogd::I18N' }, 'an App::Syslogd::I18N');
	like($handle->maketext('shutdown', 1), qr/\S/, 'and it can make a message');
};

# ===========================================================================
# App::Syslogd (load time): warnings from a dependency pass through
# ===========================================================================

# Run perl with @args in a child, return (exit code, stdout, stderr).
# Output goes to files, not pipes, and line endings are made "\n".
sub run_perl {
	my @args = @_;
	my ($out_path, $err_path) = map { File::Spec->catfile($dir, "child$serial.$_") } qw(out err);
	$serial++;
	open(my $out, '>', $out_path) or die "$out_path: $!";
	open(my $err, '>', $err_path) or die "$err_path: $!";
	# A coverage run (HARNESS_PERL_SWITCHES=-MDevel::Cover...) also measures the child
	my @switches = split(/\s+/, $ENV{HARNESS_PERL_SWITCHES} // '');
	my $pid = open3(my $in, '>&' . fileno($out), '>&' . fileno($err), $^X, grep({ length } @switches), @args);
	close($in);
	waitpid($pid, 0);
	my $exit = $? >> 8;
	close($out);
	close($err);
	my ($stdout, $stderr) = map {
		open(my $fh, '<:raw', $_) or die "$_: $!";
		my $text = do { local $/; <$fh> } // '';
		close($fh);
		$text =~ s/\r\n/\n/g;
		$text;
	} ($out_path, $err_path);
	diag("child: @args\nstdout: $stdout\nstderr: $stderr") if($ENV{TEST_VERBOSE});
	return ($exit, $stdout, $stderr);
}

subtest 'load: a warning from a dependency is not swallowed with the CHECK-block one' => sub {
	# Purpose: while it loads Sub::Private and Sub::Protected, the module
	# hides only "Too late to run CHECK block".  A different warning must
	# still reach the user.  A stand-in Sub::Private warns, then loads the
	# real one; the module is loaded at run time (require), so the CHECK
	# warning is also raised, and must be the only one hidden.
	my $fake_dir = File::Spec->catdir($dir, 'fake');
	my $fake_file = File::Spec->catfile($fake_dir, 'Sub', 'Private.pm');
	mkdir($fake_dir) or die "$fake_dir: $!";
	mkdir(File::Spec->catdir($fake_dir, 'Sub')) or die "$fake_dir/Sub: $!";
	open(my $fh, '>', $fake_file) or die "$fake_file: $!";
	print {$fh} <<"STAND_IN";
package Sub::Private;
use strict;
use warnings;
BEGIN { warn("$CONFIG{sentinel}\\n") }
my \$stand_in = __FILE__;
my (\$real) = grep { -f \$_ && \$_ ne \$stand_in } map { ref(\$_) ? () : "\$_/Sub/Private.pm" } \@INC;
defined(\$real) or die "the real Sub::Private was not found\\n";
do \$real or die "could not load \$real: \$@\\n";
1;
STAND_IN
	close($fh);

	my $script = File::Spec->catfile($dir, 'load.pl');
	open($fh, '>', $script) or die "$script: $!";
	print {$fh} "require App::Syslogd;\nprint \"loaded \$App::Syslogd::VERSION\\n\";\n";
	close($fh);

	my $lib = File::Spec->catdir($Bin, File::Spec->updir(), 'lib');
	my ($exit, $stdout, $stderr) = run_perl("-I$fake_dir", "-I$lib", $script);

	is($exit, 0, 'the module loads');
	like($stdout, qr/\Aloaded \S+\n\z/, 'and says which version');
	like($stderr, qr/^\Q$CONFIG{sentinel}\E$/m, 'the dependency warning reaches the user');
	unlike($stderr, qr/\Q$CONFIG{late_check}\E/, 'the CHECK-block warning is hidden');
};

# ===========================================================================
# Dead code report
# ===========================================================================
#
# App::Syslogd::Cache::new, line 121:
#	max_bytes => $args->{max_bytes} // $DEFAULT_MAX_BYTES
# Devel::Cover wants the right-hand side to be false once.  It is a
# constant (262_144), so it never is.  Nothing was commented out: the code
# is needed (it supplies the default), and the report is about the
# measuring tool, not about a path.

done_testing();
