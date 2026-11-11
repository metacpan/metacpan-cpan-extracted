package
	FakeClamd;

# A clamd-shaped listener that misbehaves on purpose.
#
# Half of what the client must survive cannot be provoked from a real
# clamd - a peer that accepts and never answers, a reply with no
# terminator, a connection that dies mid-reply. This produces them on
# demand, and it runs everywhere, which a real clamd does not.
#
# THE FORK RULE: the child must not keep the parent's STDOUT. It is the
# TAP pipe, the harness waits on it, and a child holding it open means a
# test run that passes every assertion and is then killed for hanging.

use strict;
use warnings;
use IO::Socket::UNIX;
use IO::Socket::INET;
use POSIX ();

sub new {
    my ($class, %opt) = @_;
    my $mode = $opt{mode} || 'ok';

    # Short by construction: sockaddr_un allows 104 bytes on the BSDs and
    # a long TMPDIR would silently truncate.
    my $path = $opt{tcp} ? undef : $opt{path} || "/tmp/cc-t-$$-" . int(rand 9999) . ".s";
    unlink $path if defined $path;

    pipe(my $ready_r, my $ready_w) or die "pipe: $!";

    my $pid = fork();
    die "fork: $!" unless defined $pid;

    if (!$pid) {
        close $ready_r;
        # Detach from the harness before anything else can write.
        open(STDOUT, '>', '/dev/null');
        open(STDERR, '>', '/dev/null');
        close STDIN;

        my $srv = $opt{tcp}
            ? IO::Socket::INET->new(
                LocalAddr => '127.0.0.1', LocalPort => 0, Proto => 'tcp', Listen => 5,
              )
            : IO::Socket::UNIX->new(
                Local => $path, Type => SOCK_STREAM, Listen => 5,
              );
        $srv or POSIX::_exit(1);

        # Tell the parent we are bound, and on TCP which port. No sleeps:
        # a fixed sleep before a connect is a race that only shows up on
        # a loaded smoker.
        syswrite($ready_w, ($opt{tcp} ? $srv->sockport : 1) . "\n");
        close $ready_w;

        # A reply carries the terminator the request was framed with:
        # zPING answers PONG\0 and nPING answers PONG\n, as clamd does.
        my $term = sub { $_[0] =~ /^n/ ? "\n" : "\0" };

        my $connections = 0;
        while (my $c = $srv->accept) {
            $connections++;
            if ($mode eq 'stall') {
                # Read the command, answer nothing, hold it open.
                sysread($c, my $b, 4096);
                sleep 60;
            }
            elsif ($mode eq 'flood') {
                # A reply that never terminates: the client must stop at
                # its ceiling rather than allocate until it dies.
                sysread($c, my $b, 4096);
                local $SIG{PIPE} = 'IGNORE';
                syswrite($c, 'A' x 65536) or last while 1;
            }
            elsif ($mode eq 'hangup') {
                sysread($c, my $b, 4096);
                close $c;
                next;
            }
            elsif ($mode eq 'slam') {
                # Gone before the client has said a word, and a flag file
                # says so, since a client that sends before the close
                # sees a different failure.
                close $c;
                if ($opt{flag}) {
                    open my $f, '>', $opt{flag};
                    close $f;
                }
                next;
            }
            elsif ($mode eq 'drip') {
                # Take the command, then one byte at a time, a different
                # count on every connection, and stop reading. The client
                # fills the socket and is stuck at whichever byte of its
                # stream the count leaves it on: over ten connections that
                # is every position in a chunk's header and its payload.
                my $cmd = '';
                while (sysread($c, my $b, 1)) {
                    $cmd .= $b;
                    last if $b eq "\0";
                }
                sysread($c, my $b, 1) for 1 .. ($connections - 1) % 10;
                select undef, undef, undef, 0.3;
                close $c;
                next;
            }
            elsif ($mode eq 'unterminated') {
                # The whole reply, then the connection closed with no
                # terminator ever sent. clamd does close after most
                # replies, so this is a reply that simply ended.
                sysread($c, my $b, 4096);
                syswrite($c, 'PONG');
                close $c;
                next;
            }
            elsif ($mode eq 'fildes') {
                # Record the SHAPE of the fd-passing handshake. A plain
                # sysread cannot see the SCM_RIGHTS payload - core Perl
                # has no recvmsg - and it cannot see message boundaries
                # either: a stream read does not stop BEFORE the
                # fd-bearing message, it reads straight through it and
                # discards the descriptor, so when both messages are
                # already queued one read returns the command and the
                # carrier byte glued together (both CPAN smoker FAILs of
                # 0.01, and a deadlock: this then waits for a second
                # message that never comes while the client waits for a
                # reply). So reframe by content: the command up to its
                # NUL, then whatever follows as the carrier. Whether the
                # descriptor really rides a separate message only a real
                # clamd can say - that is 30-live's job.
                my @steps;
                my $cmd = '';
                while (sysread($c, my $b, 1)) {
                    $cmd .= $b;
                    last if $b eq "\0";
                }
                push @steps, $cmd if length $cmd;
                if (sysread($c, my $carrier, 16)) {
                    push @steps, $carrier;
                }
                open my $log, '>', $opt{log} if $opt{log};
                if ($log) {
                    print {$log} join("|", map { my $s = $_; $s =~ s/\0/\\0/g; $s } @steps), "\n";
                    close $log;
                }
                syswrite($c, "fd[9]: OK\0");
            }
            elsif ($mode eq 'earlyreply') {
                # Answer the moment the INSTREAM command arrives, before
                # reading a single byte of the body, then hang up. A
                # client that writes the whole stream before it reads
                # gets EPIPE and reports a transport error for a scan
                # that actually produced a verdict.
                sysread($c, my $cmd, 4096);
                syswrite($c, "stream: Eicar-Test-Signature FOUND\0");
                close $c;
                next;
            }
            elsif ($mode eq 'cutoff') {
                # Take the command and a little of the body, then vanish
                # with nothing to say. This is a stream cut off with no
                # verdict - and writing into it must not kill the caller
                # with SIGPIPE.
                sysread($c, my $cmd, 4096);
                sysread($c, my $some, 4096);
                close $c;
                next;
            }
            elsif ($mode eq 'slow') {
                # Answer, but after a beat - proves a generous timeout
                # does NOT fire.
                sysread($c, my $b, 4096);
                select undef, undef, undef, 0.4;
                syswrite($c, 'PONG' . $term->($b));
            }
            elsif ($mode eq 'literal') {
                # Say exactly what the test asked for. Lets every reply
                # shape a real clamd can produce be replayed on a box
                # with no ClamAV installed at all.
                my $tail = '';
                sysread($c, $tail, 4096);
                my $t = $term->($tail);
                if ($tail =~ /INSTREAM/) {
                    while ($tail !~ /\0\0\0\0\z/) {
                        my $n = sysread($c, my $chunk, 65536);
                        last if !defined $n || $n == 0;
                        $tail = substr($tail . $chunk, -8);
                    }
                }
                syswrite($c, ($opt{literal} // '') . $t);
            }
            elsif ($mode eq 'gibberish') {
                # A reply in no recognised shape. Must come back as an
                # error - the parser's default is error and never clean,
                # which is the single most important rule it has.
                sysread($c, my $b, 4096);
                syswrite($c, "WHAT IS THIS EVEN\0");
            }
            else {
                # Answer in the shape the command asked for. Replying
                # PONG to a scan is itself an unrecognised reply, and the
                # parser is right to call that an error - so a fake that
                # does it tests the wrong thing.
                my $cmd = '';
                sysread($c, $cmd, 4096);
                my $t = $term->($cmd);
                if ($cmd =~ /INSTREAM/) {
                    # Drain until the zero-length terminator. It may
                    # already be sitting in $cmd - an empty stream writes
                    # the command and the terminator back to back, and a
                    # drain loop that always reads again hangs forever on
                    # exactly that case.
                    my $tail = $cmd;
                    while ($tail !~ /\0\0\0\0\z/) {
                        my $n = sysread($c, my $chunk, 65536);
                        last if !defined $n || $n == 0;
                        $tail = substr($tail . $chunk, -8);
                    }
                    syswrite($c, 'stream: OK' . $t);
                }
                elsif ($cmd =~ /FILDES/) {
                    # The carrier byte may already have been merged into
                    # the command read - see the fildes mode - so wait
                    # for it only if the command's NUL was the last byte
                    # received, or this blocks against a client that has
                    # nothing left to send.
                    my $i = index($cmd, "\0");
                    sysread($c, my $pad, 16) if $i == length($cmd) - 1;
                    syswrite($c, 'fd[9]: OK' . $t);
                }
                else {
                    syswrite($c, 'PONG' . $t);
                }
            }
            close $c;
        }
        POSIX::_exit(0);
    }

    close $ready_w;
    my $ok = sysread($ready_r, my $sig, 16);
    close $ready_r;
    unless ($ok) { waitpid($pid, 0); die "FakeClamd child failed to bind" }
    chomp $sig;

    return bless {
        pid  => $pid,
        path => $path,
        ($opt{tcp} ? (host => '127.0.0.1', port => $sig) : ()),
    }, $class;
}

sub path { $_[0]{path} }
sub host { $_[0]{host} }
sub port { $_[0]{port} }

# The address as ClamAV::Clamd->new takes it.
sub target {
    my ($self) = @_;
    return $self->{path} ? (socket => $self->{path})
                         : (host => $self->{host}, port => $self->{port});
}

sub stop {
    my ($self) = @_;
    return unless $self->{pid};
    kill 'KILL', $self->{pid};
    waitpid($self->{pid}, 0);
    unlink $self->{path} if defined $self->{path};
    delete $self->{pid};
    return;
}

sub DESTROY { local $?; $_[0]->stop }

1;
