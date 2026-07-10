package Sukkal_TestUtil;

# Shared helpers for the Sukkal daemon tests: fork a daemon child,
# connect to its socket, speak the line protocol, and shut it down.

use strict;
use warnings;
use File::Temp qw(tempdir);
use IO::Socket::UNIX;
use Socket      qw(SOCK_STREAM);
use POSIX       ();
use Time::HiRes qw(sleep);
use Algorithm::EventsPerSecond::Sukkal;

our @ISA       = ('Exporter');
our @EXPORT_OK = qw(spawn_daemon connect_daemon read_line req req_multi stop_daemon);
require Exporter;

# Fork a daemon child with the given constructor args; returns
# { pid, path, dir } once the socket accepts connections. A socket
# path may be forced with socket => $path, otherwise one is made in a
# fresh tempdir.
sub spawn_daemon {
	my (%args) = @_;

	my $dir  = tempdir( CLEANUP => 1 );
	my $path = delete $args{socket} // "$dir/sukkal.sock";

	my $pid = fork;
	die "fork failed: $!" unless defined $pid;

	if ( $pid == 0 ) {
		# _exit so the parent's Test::More END block does not run twice
		my $ok = eval {
			my $d = Algorithm::EventsPerSecond::Sukkal->new( socket => $path, %args );
			$SIG{TERM} = sub { $d->stop };
			$d->run;
			1;
		};
		warn $@ if !$ok;
		POSIX::_exit( $ok ? 0 : 1 );
	} ## end if ( $pid == 0 )

	for ( 1 .. 100 ) {
		my $probe = IO::Socket::UNIX->new( Type => SOCK_STREAM, Peer => $path );
		if ($probe) {
			close $probe;
			return { pid => $pid, path => $path, dir => $dir };
		}
		sleep 0.1;
	}
	kill 'KILL', $pid;
	waitpid $pid, 0;
	die "daemon did not come up on $path";
} ## end sub spawn_daemon

sub connect_daemon {
	my ($d) = @_;
	return IO::Socket::UNIX->new( Type => SOCK_STREAM, Peer => $d->{path} )
		|| die "cannot connect to $d->{path}: $!";
}

# read one reply line, stripped of its terminator; undef at EOF
sub read_line {
	my ($sock) = @_;
	my $line = <$sock>;
	return undef unless defined $line;
	$line =~ s/\r?\n\z//;
	return $line;
}

# send a command, read its single-line reply
sub req {
	my ( $sock, $cmd ) = @_;
	print $sock "$cmd\n";
	return read_line($sock);
}

# send a command with a multi-line reply; returns (header, lines up to END)
sub req_multi {
	my ( $sock, $cmd ) = @_;
	print $sock "$cmd\n";
	my $hdr = read_line($sock);
	my @lines;
	while ( defined( my $l = read_line($sock) ) ) {
		last if $l eq 'END';
		push @lines, $l;
	}
	return ( $hdr, @lines );
} ## end sub req_multi

# SIGTERM the daemon and reap it; returns the wait status ($?)
sub stop_daemon {
	my ($d) = @_;
	kill 'TERM', $d->{pid};
	waitpid $d->{pid}, 0;
	return $?;
}

1;
