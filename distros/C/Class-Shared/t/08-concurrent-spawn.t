use strict;
use warnings;

use Test::More;
use Test::Needs;
use Class::Shared ();

# Two frontends starting at the same moment in one directory race for the spawn
# lock and for the socket that now has to be shared between classes.  That path
# needs fork() to set the race up and a unix socket in an owner-only directory.
# Whether this perl can make the socket is asked of the module, and whether a
# directory here can really be made owner-only is asked of Test::Permissions.
BEGIN {
	test_needs 'Test::Permissions';

	plan skip_all => 'this races fork()ed frontends over a unix socket in an '
		. 'owner-only directory, which this perl cannot provide '
		. '(Class::Shared is Unix-only)'
		unless Class::Shared::_has_unix_sockets()
			&& Test::Permissions::can_revoke_create();
}

use File::Temp qw(tempdir);
use POSIX ();
use lib 't/lib';

use Class::Shared::Frontend;

# Whether this file can run at all, and the race it sets up, are settled here,
# at compile time, before a test is output: a skip_all after tests have run is
# a plan for zero tests, which TAP reads as a bad plan, so no test ever added
# above a skip can be allowed to make one.  The children are forked here too,
# so the fork that could fail cannot come after a test either; each one writes
# its report and _exit()s inside this block, so it never returns to run the
# parent's half of the file.
our ($dir, $reader, $writer, @kids);

BEGIN {
	$dir = tempdir(CLEANUP => 1);

	# Different classes, so whichever frontend wins the lock, the other has to
	# be given the backend that is already there with a class loaded it did not
	# ask for; both are released by the same byte, so they reach the lock
	# together.
	my @runners = (
		{ name => 'counter', class => 'Shared::Counter', start => 5, method => 'value' },
		{ name => 'tally',   class => 'Shared::Tally',   start => 7, method => 'total' },
	);

	pipe($reader, $writer) or plan skip_all => "cannot create a pipe: $!";

	for my $runner (@runners) {
		my $pid = fork;
		plan skip_all => "cannot fork: $!" unless defined $pid;

		if (!$pid) {
			close $writer;

			# The starting gun: read returns when the parent closes the write
			# end.
			my $go;
			sysread($reader, $go, 1);
			close $reader;

			my $report = eval {
				my $frontend = Class::Shared::Frontend->new(
					$runner->{class},
					ctor => [start => $runner->{start}],
					dir  => $dir,
				);

				my $method = $runner->{method};

				join ' ', $frontend->shared_pid, $frontend->$method;
			};

			open(my $out, '>', "$dir/$runner->{name}.out") or POSIX::_exit(3);
			print {$out} defined $report ? "$report\n" : "ERROR: $@";
			close $out;

			# _exit, so Test::More's END block does not run in the child.
			POSIX::_exit(defined $report ? 0 : 1);
		}

		push @kids, { %{$runner}, pid => $pid };
	}
}

close $writer;
close $reader;

my @exits;
for my $kid (@kids) {
	waitpid($kid->{pid}, 0);
	push @exits, $? >> 8;
}

is_deeply(\@exits, [0, 0], 'both frontends came up')
	or diag 'exit statuses: ' . join(', ', @exits);

my %report;
for my $kid (@kids) {
	my $path = "$dir/$kid->{name}.out";

	open(my $fh, '<', $path) or do {
		fail("cannot read what $kid->{name} reported");
		next;
	};

	my $line = <$fh>;
	close $fh;

	$line = defined $line ? $line : '';
	chomp $line;

	diag("$kid->{name} said: $line") if $line =~ /\AERROR/;

	my ($pid, $value) = split / /, $line;
	$report{ $kid->{name} } = { pid => $pid, value => $value };
}

isnt($report{counter}{pid}, undef, 'the first frontend reached a backend');
is($report{counter}{pid}, $report{tally}{pid},
	'and both frontends ended up in one backend');
isnt($report{counter}{pid}, $$, 'which is a backend of its own, not this process');
is($report{counter}{value}, 5, 'the first class answered from it');
is($report{tally}{value}, 7, 'and the second class did too');

# The children have gone, so their objects have gone with them, but the modules
# stay loaded: one backend, both classes.
my $backend_pid = $report{counter}{pid};

my $status = `$^X -Ilib -It/lib bin/class-shared status --dir $dir 2>&1`;
like($status, qr/^pid $backend_pid\b/m, 'nothing else serves the directory')
	or diag $status;
like($status, qr/^classes: Shared::Counter, Shared::Tally$/m,
	'and the one backend has both classes loaded') or diag $status;

my $stopped = `$^X -Ilib -It/lib bin/class-shared stop --dir $dir 2>&1`;
is($?, 0, 'the backend stops') or diag $stopped;
ok(!-e Class::Shared::socket_path($dir), 'and leaves no socket behind');

done_testing();
