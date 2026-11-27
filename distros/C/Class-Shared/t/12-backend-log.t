use strict;
use warnings;

use Test::More;
use File::Temp qw(tempdir);
use POSIX ();

use Class::Shared::Backend ();

# The backend writes its log through Log::Abstraction.  These tests call the
# private _log directly, so no socket is made and none is needed.

my $dir = tempdir(CLEANUP => 1);

sub slurp {
	my ($path) = @_;

	open(my $fh, '<', $path) or BAIL_OUT("cannot read $path: $!");
	my $text = do { local $/; <$fh> };
	close($fh) or BAIL_OUT("cannot close $path: $!");

	return $text;
}

sub backend {
	my ($name) = @_;

	return Class::Shared::Backend->new(socket => "$dir/$name.sock", log => "$dir/$name.log");
}

# ------------------------------------------------------------------ the format

{
	my $b = backend('format');

	is($b->_log('first'), 1, '_log reports success');
	$b->_log('second');

	# Read while the backend still exists: a test and a person tailing the log
	# must see a line when it is written, not when the backend is destroyed.
	my @lines = split /\n/, slurp("$dir/format.log");

	is(scalar @lines, 2, 'one line for each message, written at once');
	like($lines[0], qr/\A\[$$\] \d{4}-\d\d-\d\d \d\d:\d\d:\d\d first\z/,
		'a line is [pid] date time message');
	like($lines[1], qr/ second\z/, 'in the order logged');
}

# ----------------------------------------------------------------- awkward text

{
	my $b = backend('text');

	$b->_log("two\nlines");
	$b->_log('100% of %s and %message% are literal');
	$b->_log("caf\x{e9} and \x{263A}");

	my $text = slurp("$dir/text.log");

	unlike($text, qr/^two$/m, 'a line break in a message does not end the entry');
	like($text, qr/two\n\tlines/, 'the next line is indented, so it cannot pass for a new entry');
	like($text, qr/100% of %s and %message% are literal/, 'percent signs in a message are not expanded');
	is(scalar(() = $text =~ /^\[$$\] /mg), 3, 'three messages are three entries');
}

# ---------------------------------------------------------------------- levels

{
	my $b = backend('levels');

	$b->_log('plain');
	$b->_log('trouble', 'warn');
	$b->_log('failure', 'error');

	my $text = slurp("$dir/levels.log");

	like($text, qr/ plain\n/, 'the default level is logged');
	like($text, qr/ trouble\n/, 'warn is logged');
	like($text, qr/ failure\n/, 'error is logged');
}

# --------------------------------------------------------------- default path

{
	my $b = Class::Shared::Backend->new(socket => "$dir/default.sock");

	$b->_log('to the default');

	like(slurp("$dir/default.sock.log"), qr/ to the default\n/,
		'with no log option, the log sits next to the socket');
}

# -------------------------------------------------------------- a log that fails

{
	my $b = Class::Shared::Backend->new(socket => "$dir/bad.sock", log => "$dir/no-such-dir/x.log");

	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };

	my $result = eval { $b->_log('nowhere to go'); 1 };

	ok($result, 'a log that cannot be written never makes the backend die');
}

# -------------------------------------------------------------------- new process

# The pid is in each line, so a backend that forks (as it does to detach) must
# not go on writing the parent's pid.
SKIP: {
	# Where fork is emulated with threads (Windows) the child shares this
	# process, so ending it with _exit would end the whole test.
	skip 'fork is emulated here, so there is no second process to name', 2
		if $^O eq 'MSWin32';

	my $b = backend('forked');

	$b->_log('before');

	my $pid = fork;
	BAIL_OUT("cannot fork: $!") unless defined $pid;

	if (!$pid) {
		$b->_log('in the child');
		POSIX::_exit(0);
	}

	waitpid($pid, 0);

	my $text = slurp("$dir/forked.log");

	like($text, qr/^\[$$\] .* before$/m, 'the parent line carries the parent pid');
	like($text, qr/^\[$pid\] .* in the child$/m, 'the child line carries the child pid');
}

done_testing();
