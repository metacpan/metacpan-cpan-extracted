package Algorithm::EventsPerSecond::Sukkal;

use 5.006;
use strict;
use warnings;

use Errno qw(EAGAIN EWOULDBLOCK EINTR);
use IO::Select;
use IO::Socket::UNIX;
use Socket qw(SOCK_STREAM);
use Algorithm::EventsPerSecond;

=encoding utf8

=head1 NAME

Algorithm::EventsPerSecond::Sukkal - A unix-socket daemon serving per-key sliding-window event rates.

=head1 VERSION

Version 0.1.0

=cut

our $VERSION = '0.1.0';

# per-connection buffer ceilings: a single line may not span more than
# _RBUF_MAX, and a client that stops reading is dropped once _WBUF_MAX
# of replies have queued up
use constant {
	_RBUF_MAX   => 1024 * 1024,
	_WBUF_MAX   => 8 * 1024 * 1024,
	_READ_CHUNK => 65536,
};

=head1 SYNOPSIS

    use Algorithm::EventsPerSecond::Sukkal;

    my $sukkal = Algorithm::EventsPerSecond::Sukkal->new(
        socket => '/var/run/iqbi-damiq.sock',
        window => 60,
    );

    $SIG{TERM} = $SIG{INT} = sub { $sukkal->stop };

    $sukkal->run;    # blocks until stop()

Then, from any client:

    use IO::Socket::UNIX;

    my $sock = IO::Socket::UNIX->new(
        Type => SOCK_STREAM,
        Peer => '/var/run/iqbi-damiq.sock',
    );

    print $sock "MARK requests\n";      # fire and forget
    print $sock "MARK errors 3\n";

    print $sock "RATE requests\n";
    my $reply = <$sock>;                # "OK 41.2\n"

    print $sock "MARKRATE requests\n";  # mark and rate in one call
    my $rate = <$sock>;                 # "OK 41.3\n"

=head1 DESCRIPTION

A sukkal is the vizier-messenger of a Mesopotamian court: petitioners
speak to it, and it relays word of them to the throne. This sukkal
listens on a unix stream socket, records events marked against
arbitrary client-chosen keys, and answers queries about their rates.
Each key gets its own L<Algorithm::EventsPerSecond> meter, so C<mark>
stays O(1) and memory per key is constant regardless of event volume.

The daemon is a single process driven by a non-blocking select loop;
no non-core modules are required. Marks arriving back-to-back on a
connection are coalesced per key and applied with a single C<mark($n)>
call, so the hot path is dominated by socket reads and line parsing,
not by the meters.

Keys that go idle longer than L</idle_timeout> are evicted by a
periodic sweep. Because the timeout is never shorter than the window,
an evicted key by definition has zero events inside the window, so
queries for it correctly read as zero; the only state lost is its
lifetime L</TOTAL>.

The bundled launcher script is L<iqbi-damiq>, "She said 'it is fine!'".

=head1 METHODS

=head2 new( socket => $path, %options )

Construct a daemon. Nothing is bound until L</run> is called.

=over 4

=item socket

Path of the unix socket to listen on. Required. A stale socket file
left by a dead daemon is removed automatically; a live listener on the
same path is an error.

=item window

Averaging window in seconds for every meter, as in
L<Algorithm::EventsPerSecond/new>. Defaults to 60. Each key's memory
scales linearly with the window; see L</MEMORY USAGE>.

=item max_keys

Maximum number of distinct keys tracked at once. Marks for new keys
beyond the limit are rejected with an error reply. 0 means unlimited.
Defaults to 100000. This is the daemon's memory ceiling: worst case
is C<max_keys> live meters, each of a size fixed by the window; see
L</MEMORY USAGE>.

=item max_key_length

Maximum key length in bytes. Keys may be any non-whitespace,
non-control bytes. Defaults to 255.

=item idle_timeout

Seconds a key may go unmarked before the sweep evicts it. Must be at
least C<window>. Defaults to twice the window.

=item sweep_interval

Seconds between eviction sweeps. Defaults to 30.

=item max_clients

Maximum simultaneous client connections; further connections are
closed immediately. 0 means unlimited, the default.

=item listen_backlog

The listen(2) backlog. Defaults to 128.

=item socket_mode

Octal permission string, e.g. C<'0770'>, applied to the socket file
after binding. By default the process umask decides.

=back

=cut

sub new {
	my ( $class, %args ) = @_;

	my $self = {
		socket         => $args{socket},
		window         => $args{window}         // 60,
		max_keys       => $args{max_keys}       // 100_000,
		max_key_length => $args{max_key_length} // 255,
		sweep_interval => $args{sweep_interval} // 30,
		max_clients    => $args{max_clients}    // 0,
		listen_backlog => $args{listen_backlog} // 128,
	};

	die "socket path required\n"
		unless defined $self->{socket} && length $self->{socket};

	for my $opt (qw(window max_key_length sweep_interval listen_backlog)) {
		die "$opt must be a positive integer\n"
			unless $self->{$opt} =~ /^\d+$/ && $self->{$opt} > 0;
	}
	for my $opt (qw(max_keys max_clients)) {
		die "$opt must be a non-negative integer\n"
			unless $self->{$opt} =~ /^\d+$/;
	}

	$self->{idle_timeout} = $args{idle_timeout} // $self->{window} * 2;
	die "idle_timeout must be an integer >= window\n"
		unless $self->{idle_timeout} =~ /^\d+$/
		&& $self->{idle_timeout} >= $self->{window};

	if ( defined $args{socket_mode} ) {
		die "socket_mode must be an octal string, e.g. '0770'\n"
			unless $args{socket_mode} =~ /^0?[0-7]{3}$/;
		$self->{socket_mode} = oct $args{socket_mode};
	}

	$self->{meters}     = {};                                                             # key => { m => meter, seen => epoch }
	$self->{conns}      = {};                                                             # fd  => { fh, id, rbuf, wbuf, closing }
	$self->{running}    = 0;
	$self->{started}    = time();
	$self->{self_meter} = Algorithm::EventsPerSecond->new( window => $self->{window} );
	$self->{key_re}     = qr/^[\x21-\x7E\x80-\xFF]{1,$self->{max_key_length}}$/;

	return bless $self, $class;
} ## end sub new

=head2 run

Bind the socket and serve until L</stop> is called (typically from a
signal handler; signals interrupt the select and are honored
promptly). On return the socket file has been unlinked and all client
connections closed. Dies if the socket cannot be bound.

=cut

sub run {
	my ($self) = @_;

	die "already running\n" if $self->{running};

	$self->_listen;
	local $SIG{PIPE} = 'IGNORE';

	my $rsel = $self->{rsel} = IO::Select->new( $self->{listener} );
	my $wsel = $self->{wsel} = IO::Select->new;

	$self->{running}    = 1;
	$self->{next_sweep} = time() + $self->{sweep_interval};

	while ( $self->{running} ) {
		my $timeout = $self->{next_sweep} - time();
		$timeout = 0 if $timeout < 0;

		my ( $r, $w ) = IO::Select->select( $rsel, $wsel, undef, $timeout );

		for my $fh ( @{ $r || [] } ) {
			if ( fileno($fh) == $self->{listener_fd} ) {
				$self->_accept;
			} else {
				$self->_read_client($fh);
			}
		}

		for my $fh ( @{ $w || [] } ) {
			# a connection dropped during the read pass may still be in
			# this list; its handle is closed, so fileno is undef
			my $id = fileno $fh;
			next unless defined $id && $self->{conns}{$id};
			$self->_flush( $self->{conns}{$id} );
		}

		if ( time() >= $self->{next_sweep} ) {
			$self->_sweep;
			$self->{next_sweep} = time() + $self->{sweep_interval};
		}
	} ## end while ( $self->{running} )

	$self->_shutdown;
	return $self;
} ## end sub run

=head2 stop

Ask a running daemon to shut down. Safe to call from a signal handler;
the L</run> loop notices on its next wakeup. Returns the daemon
object.

=cut

sub stop {
	my ($self) = @_;
	$self->{running} = 0;
	return $self;
}

sub _listen {
	my ($self) = @_;
	my $path = $self->{socket};

	if ( -e $path ) {
		die "$path exists and is not a socket\n" unless -S _;
		my $probe = IO::Socket::UNIX->new( Type => SOCK_STREAM, Peer => $path );
		die "something is already listening on $path\n" if $probe;
		unlink $path or die "cannot remove stale socket $path: $!\n";
	}

	my $listener = IO::Socket::UNIX->new(
		Type   => SOCK_STREAM,
		Local  => $path,
		Listen => $self->{listen_backlog},
	) or die "cannot listen on $path: $!\n";
	$listener->blocking(0);

	chmod $self->{socket_mode}, $path if defined $self->{socket_mode};

	$self->{listener}    = $listener;
	$self->{listener_fd} = fileno $listener;
	return;
} ## end sub _listen

sub _accept {
	my ($self) = @_;

	while ( my $fh = $self->{listener}->accept ) {
		if ( $self->{max_clients}
			&& keys %{ $self->{conns} } >= $self->{max_clients} )
		{
			close $fh;
			next;
		}
		$fh->blocking(0);
		my $id = fileno $fh;
		$self->{conns}{$id} = {
			fh      => $fh,
			id      => $id,
			rbuf    => '',
			wbuf    => '',
			closing => 0,
		};
		$self->{rsel}->add($fh);
	} ## end while ( my $fh = $self->{listener}->accept )
	return;
} ## end sub _accept

sub _read_client {
	my ( $self, $fh ) = @_;
	my $id = fileno $fh;
	my $c  = $self->{conns}{$id} or return;

	my $eof;
	# bounded so one firehose client cannot starve the rest of the loop
	for ( 1 .. 16 ) {
		my $n = sysread $fh, my $chunk, _READ_CHUNK;
		if ( !defined $n ) {
			last if $!{EAGAIN} || $!{EWOULDBLOCK} || $!{EINTR};
			$eof = 1;
			last;
		}
		if ( $n == 0 ) { $eof = 1; last }
		$c->{rbuf} .= $chunk;
		last if $n < _READ_CHUNK;
	} ## end for ( 1 .. 16 )

	if ( length $c->{rbuf} > _RBUF_MAX ) {
		$self->_send( $c, "ERR line too long\n" );
		return $self->_drop($c);
	}

	$self->_process($c);
	$self->_drop($c) if $eof && $self->{conns}{$id};
	return;
} ## end sub _read_client

sub _process {
	my ( $self, $c ) = @_;

	my $buf = $c->{rbuf};
	my $pos = 0;
	my %pending;
	my $pending_new = 0;

	while ( ( my $nl = index $buf, "\n", $pos ) >= 0 ) {
		my $line = substr $buf, $pos, $nl - $pos;
		$pos = $nl + 1;
		$line =~ s/\r\z//;

		my ( $cmd, $key, $extra ) = split ' ', $line, 3;
		next unless defined $cmd;
		$cmd = uc $cmd;
		$extra =~ s/\s+\z// if defined $extra;

		# hot path: marks are coalesced per key and applied in one
		# mark($n) call, either just before the next query or at the
		# end of the buffer
		if ( $cmd eq 'MARK' ) {
			my $count = 1;
			if ( defined $extra ) {
				if ( $extra =~ /^\d{1,15}$/ && $extra > 0 ) {
					$count = $extra;
				} else {
					$self->_send( $c, "ERR bad count\n" );
					next;
				}
			}
			if ( !defined $key || $key !~ $self->{key_re} ) {
				$self->_send( $c, "ERR bad key\n" );
				next;
			}
			if ( !exists $self->{meters}{$key} && !exists $pending{$key} ) {
				if ( $self->{max_keys}
					&& keys( %{ $self->{meters} } ) + $pending_new >= $self->{max_keys} )
				{
					$self->_send( $c, "ERR key limit reached\n" );
					next;
				}
				$pending_new++;
			}
			$pending{$key} += $count;
			next;
		} ## end if ( $cmd eq 'MARK' )

		if (%pending) {
			$self->_apply_marks( \%pending );
			%pending     = ();
			$pending_new = 0;
		}
		$self->_command( $c, $cmd, $key, $extra );
		last if $c->{closing};
	} ## end while ( ( my $nl = index $buf, "\n", $pos ) >=...)

	$self->_apply_marks( \%pending ) if %pending;
	$c->{rbuf} = $pos ? substr( $buf, $pos ) : $buf;
	return;
} ## end sub _process

sub _apply_marks {
	my ( $self, $pending ) = @_;
	my $meters = $self->{meters};
	my $now    = time();
	my $n      = 0;

	for my $key ( keys %$pending ) {
		my $e = $meters->{$key} ||= { m => Algorithm::EventsPerSecond->new( window => $self->{window} ) };
		$e->{m}->mark( $pending->{$key} );
		$e->{seen} = $now;
		$n += $pending->{$key};
	}
	$self->{self_meter}->mark($n);
	return;
} ## end sub _apply_marks

sub _command {
	my ( $self, $c, $cmd, $key, $extra ) = @_;
	my $meters = $self->{meters};

	if ( $cmd eq 'RATE' || $cmd eq 'COUNT' || $cmd eq 'TOTAL' ) {
		return $self->_send( $c, "ERR bad key\n" )
			unless defined $key && $key =~ $self->{key_re};
		my $e = $meters->{$key};
		my $v
			= !$e             ? 0
			: $cmd eq 'RATE'  ? sprintf( '%.6g', $e->{m}->rate )
			: $cmd eq 'COUNT' ? $e->{m}->count
			:                   $e->{m}->total;
		return $self->_send( $c, "OK $v\n" );
	} ## end if ( $cmd eq 'RATE' || $cmd eq 'COUNT' || ...)

	if ( $cmd eq 'MARKRATE' ) {
		my $count = 1;
		if ( defined $extra ) {
			return $self->_send( $c, "ERR bad count\n" )
				unless $extra =~ /^\d{1,15}$/ && $extra > 0;
			$count = $extra;
		}
		return $self->_send( $c, "ERR bad key\n" )
			unless defined $key && $key =~ $self->{key_re};
		if (   !exists $meters->{$key}
			&& $self->{max_keys}
			&& keys(%$meters) >= $self->{max_keys} )
		{
			return $self->_send( $c, "ERR key limit reached\n" );
		}
		$self->_apply_marks( { $key => $count } );
		return $self->_send( $c, sprintf( "OK %.6g\n", $meters->{$key}{m}->rate ) );
	} ## end if ( $cmd eq 'MARKRATE' )

	if ( $cmd eq 'STATS' ) {
		if ( defined $key ) {
			return $self->_send( $c, "ERR bad key\n" )
				unless $key =~ $self->{key_re};
			my $e = $meters->{$key};
			my ( $rate, $count, $total )
				= $e
				? ( sprintf( '%.6g', $e->{m}->rate ), $e->{m}->count, $e->{m}->total )
				: ( 0, 0, 0 );
			return $self->_send( $c, "OK rate=$rate count=$count total=$total window=$self->{window}\n" );
		} ## end if ( defined $key )
		my $sm = $self->{self_meter};
		return $self->_send(
			$c,
			sprintf "OK keys=%d clients=%d rate=%.6g count=%d total=%d uptime=%d window=%d backend=%s\n",
			scalar keys %$meters,
			scalar keys %{ $self->{conns} },
			$sm->rate,       $sm->count, $sm->total, time() - $self->{started},
			$self->{window}, Algorithm::EventsPerSecond->backend
		);
	} ## end if ( $cmd eq 'STATS' )

	if ( $cmd eq 'KEYS' ) {
		my @keys = sort keys %$meters;
		my $out  = 'OK ' . scalar(@keys) . "\n";
		$out .= "$_\n" for @keys;
		return $self->_send( $c, $out . "END\n" );
	}

	if ( $cmd eq 'DUMP' ) {
		my @keys = sort keys %$meters;
		my $out  = 'OK ' . scalar(@keys) . "\n";
		for my $k (@keys) {
			my $m = $meters->{$k}{m};
			$out .= sprintf "%s %.6g %d %d\n", $k, $m->rate, $m->count, $m->total;
		}
		return $self->_send( $c, $out . "END\n" );
	}

	if ( $cmd eq 'RESET' ) {
		return $self->_send( $c, "ERR bad key\n" )
			unless defined $key && $key =~ $self->{key_re};
		if ( my $e = $meters->{$key} ) {
			$e->{m}->reset;
			$e->{seen} = time();
		}
		return $self->_send( $c, "OK\n" );
	}

	if ( $cmd eq 'DEL' ) {
		return $self->_send( $c, "ERR bad key\n" )
			unless defined $key && $key =~ $self->{key_re};
		delete $meters->{$key};
		return $self->_send( $c, "OK\n" );
	}

	if ( $cmd eq 'PING' ) {
		return $self->_send( $c, "OK PONG\n" );
	}

	if ( $cmd eq 'QUIT' ) {
		$c->{closing} = 1;
		$self->{rsel}->remove( $c->{fh} );
		return $self->_send( $c, "OK BYE\n" );
	}

	return $self->_send( $c, "ERR unknown command\n" );
} ## end sub _command

sub _send {
	my ( $self, $c, $data ) = @_;

	if ( $c->{wbuf} eq '' ) {
		my $n = syswrite $c->{fh}, $data;
		if ( defined $n ) {
			if ( $n == length $data ) {
				$self->_drop($c) if $c->{closing};
				return;
			}
			$data = substr $data, $n;
		} elsif ( !( $!{EAGAIN} || $!{EWOULDBLOCK} || $!{EINTR} ) ) {
			return $self->_drop($c);
		}
	} ## end if ( $c->{wbuf} eq '' )

	$c->{wbuf} .= $data;
	return $self->_drop($c) if length $c->{wbuf} > _WBUF_MAX;
	$self->{wsel}->add( $c->{fh} );
	return;
} ## end sub _send

sub _flush {
	my ( $self, $c ) = @_;

	my $n = syswrite $c->{fh}, $c->{wbuf};
	if ( !defined $n ) {
		return if $!{EAGAIN} || $!{EWOULDBLOCK} || $!{EINTR};
		return $self->_drop($c);
	}
	substr( $c->{wbuf}, 0, $n ) = '';
	if ( $c->{wbuf} eq '' ) {
		$self->{wsel}->remove( $c->{fh} );
		$self->_drop($c) if $c->{closing};
	}
	return;
} ## end sub _flush

sub _drop {
	my ( $self, $c ) = @_;
	my $fh = $c->{fh};
	$self->{rsel}->remove($fh);
	$self->{wsel}->remove($fh);
	delete $self->{conns}{ $c->{id} };
	close $fh;
	return;
}

sub _sweep {
	my ($self) = @_;
	my $meters = $self->{meters};
	my $cutoff = time() - $self->{idle_timeout};
	delete @$meters{ grep { $meters->{$_}{seen} < $cutoff } keys %$meters };
	return;
}

sub _shutdown {
	my ($self) = @_;
	$self->_drop($_) for values %{ $self->{conns} };
	if ( $self->{listener} ) {
		close delete $self->{listener};
		unlink $self->{socket};
	}
	delete @{$self}{qw(rsel wsel listener_fd)};
	return;
} ## end sub _shutdown

=head1 PROTOCOL

The protocol is line-based over a unix stream socket. Lines end in
C<\n> (a trailing C<\r> is tolerated) and hold whitespace-separated
tokens; commands are case-insensitive. Keys are any non-whitespace,
non-control bytes up to L</max_key_length> long. Replies are a single
C<OK ...> or C<ERR ...> line, except L</KEYS> and L</DUMP>, which are
multi-line. Commands may be pipelined freely; replies come back in
order.

=head2 MARK <key> [<count>]

Record one event, or C<count> events, against C<key>, creating the key
if it is new. Nothing is replied on success
so writers never have to read; malformed input or hitting
L</max_keys> replies C<ERR ...>.

=head2 RATE <key>

Reply C<OK n> with the key's events per second averaged over the
window. Unknown keys read as C<OK 0>.

=head2 MARKRATE <key> [<count>]

Record one event, or C<count> events, against C<key> exactly as
L</MARK> would, then reply C<OK n> with the key's rate as L</RATE>
would — a mark and a query in a single round trip. Rejects with
C<ERR ...> under the same conditions as L</MARK>.

=head2 COUNT <key>

Reply C<OK n> with the number of events inside the window. Unknown
keys read as C<OK 0>.

=head2 TOTAL <key>

Reply C<OK n> with the key's lifetime event count. Unknown (or
evicted) keys read as C<OK 0>.

=head2 STATS [<key>]

With a key, reply C<OK rate=n count=n total=n window=n> for it. With
no key, reply the daemon's own statistics: tracked keys, connected
clients, the daemon-wide mark rate and totals, uptime, window, and
which L<Algorithm::EventsPerSecond> backend is loaded.

=head2 KEYS

Reply C<OK n>, then one key per line, then C<END>.

=head2 DUMP

Reply C<OK n>, then C<< <key> <rate> <count> <total> >> per line, then
C<END>. Note each row costs an O(window) scan, so on huge key counts
with long windows prefer targeted queries.

=head2 RESET <key>

Zero the key's meter and lifetime total, as
L<Algorithm::EventsPerSecond/reset>. Replies C<OK>.

=head2 DEL <key>

Forget the key entirely. Replies C<OK>.

=head2 PING

Replies C<OK PONG>.

=head2 QUIT

Replies C<OK BYE> and closes the connection.

=head1 PERFORMANCE NOTES

Batch marks: many C<MARK> lines per write, ideally repeated keys
back-to-back, or a single C<MARK key 1000>. The daemon coalesces
consecutive marks per key into one meter call, so the ceiling is
socket throughput and line parsing rather than the meters — which, on
the XS backend, barely notice.

Memory is bounded by L</max_keys> and L</window>; see L</MEMORY
USAGE> for how to size them.

=head1 MEMORY USAGE

Every key owns one L<Algorithm::EventsPerSecond> meter, and a meter's
size is set entirely by the window: two ring buffers of one slot per
window second, counts in one and timestamps in the other. Event
volume does not matter; a key marked once costs the same as a key
marked a million times. The worst-case daemon footprint is therefore

    max_keys * bytes_per_key

where bytes_per_key is the two buffers plus a fixed per-key overhead
(the meter object, the key string, and its slot in the key table).
On the XS backend a slot is a packed C<int64_t>, so

    bytes_per_key ~= 2 * 8 * window + 800

and on the pure-Perl backend a slot is a perl scalar of roughly 24
bytes, so

    bytes_per_key ~= 2 * 24 * window + 2000

Measured resident-set growth per key (perl 5.42, 64-bit), and the
worst case that implies at the default max_keys of 100000:

    window  backend  per key   at 100000 keys
        60  XS       ~1.7 KB   ~170 MB
        60  PP       ~4.9 KB   ~490 MB
       300  XS       ~5.2 KB   ~520 MB
       300  PP       ~16 KB    ~1.6 GB

Keys are client-chosen, which is why L</max_keys> exists: size it so
that C<max_keys * bytes_per_key> is something the host can absorb.
The worst case only materializes if that many distinct keys are all
marked within one L</idle_timeout>; the sweep evicts idle keys and
returns their memory.

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-algorithm-eventspersecond at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Algorithm-EventsPerSecond>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Algorithm::EventsPerSecond::Sukkal

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Algorithm-EventsPerSecond>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Algorithm-EventsPerSecond>

=item * Search CPAN

L<https://metacpan.org/release/Algorithm-EventsPerSecond>

=back

=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by Zane C. Bowers-Hadley.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999


=cut

1;    # End of Algorithm::EventsPerSecond::Sukkal
