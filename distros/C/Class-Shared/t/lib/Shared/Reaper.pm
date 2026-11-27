package Shared::Reaper;

# Ends the processes a test started even when the test cannot do it itself: when
# a resource limit or a signal kills it, no END block runs.  A small watcher
# process waits for the test to go and then kills everything on its list.

use strict;
use warnings;

use POSIX ();

sub new {
	my ($class, $list) = @_;

	open(my $fh, '>', $list) or die "$list: $!";
	close($fh);

	my $parent = $$;
	my $pid = fork() // die "fork: $!";
	if (!$pid) {
		# Holding the harness's pipes would make it wait for this process.
		open(STDIN, '<', '/dev/null');
		open(STDOUT, '>', '/dev/null');
		open(STDERR, '>', '/dev/null');

		# The list is read while the test is alive: it may be in a temporary
		# directory that is removed as the test ends.
		my %doomed;
		my $read = sub {
			open(my $in, '<', $list) or return;
			while (my $line = <$in>) {
				$doomed{$1} = 1 if $line =~ /\A(\d+)\n\z/;
			}
		};
		while (getppid() == $parent) {
			$read->();
			select(undef, undef, undef, 0.1);
		}
		$read->();
		kill 'KILL', keys %doomed if %doomed;
		POSIX::_exit(0);
	}

	return bless { list => $list, watcher => $pid, owner => $$ }, $class;
}

sub add {
	my ($self, $pid) = @_;

	open(my $fh, '>>', $self->{list}) or die "$self->{list}: $!";
	print {$fh} "$pid\n";
	close($fh);

	return $pid;
}

# After the test has ended its processes itself, the watcher is not needed.
sub dismiss {
	my $self = shift;

	return unless $$ == $self->{owner} && $self->{watcher};

	kill 'KILL', $self->{watcher};
	waitpid($self->{watcher}, 0);
	$self->{watcher} = 0;

	return;
}

1;
