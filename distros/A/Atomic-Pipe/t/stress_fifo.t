use Test2::V0;
use Test2::IPC;
use Atomic::Pipe;

BEGIN { *PIPE_BUF = Atomic::Pipe->can('PIPE_BUF') }

BEGIN {
    my $path = __FILE__;
    $path =~ s{[^/]+\.t$}{worker.pm};
    require "./$path";
}

use POSIX qw/mkfifo/;
use File::Temp qw/tempdir/;
use File::Spec;

my $tempdir = tempdir(CLEANUP => 1);
my $fifo = File::Spec->catfile($tempdir, 'fifo');
unless (eval { mkfifo($fifo, 0700) or die "Failed to make fifo: $!" }) {
    die $@ unless $@ =~ m/not implemented on this architecture/;
    skip_all $@;
};

my $r = Atomic::Pipe->read_fifo($fifo);

my $COUNT = 10_000;

worker { my $w = Atomic::Pipe->write_fifo($fifo); $w->write_message("aaa" x PIPE_BUF) for 1 .. $COUNT };
worker { my $w = Atomic::Pipe->write_fifo($fifo); $w->write_message("bbb" x PIPE_BUF) for 1 .. $COUNT };
worker { my $w = Atomic::Pipe->write_fifo($fifo); $w->write_message("ccc" x PIPE_BUF) for 1 .. $COUNT };
worker { my $w = Atomic::Pipe->write_fifo($fifo); $w->write_message("ddd" x PIPE_BUF) for 1 .. $COUNT };
worker { my $w = Atomic::Pipe->write_fifo($fifo); $w->write_message("eee" x PIPE_BUF) for 1 .. $COUNT };

# Without this windows blocks in the main thread and the other threads never do their work.
sleep 4 if $^O eq 'MSWin32';

my %seen;
while (my $msg = $r->read_message) {
    is(
        $msg,
        in_set(
            ("aaa" x PIPE_BUF),
            ("bbb" x PIPE_BUF),
            ("ccc" x PIPE_BUF),
            ("ddd" x PIPE_BUF),
            ("eee" x PIPE_BUF),
        ),
        "Message is valid, not mangled"
    );

    $seen{substr($msg, 0, 1)}++;

    last if ++$seen{TOTAL} >= (5 * $COUNT);
}

delete $seen{TOTAL};

is(
    \%seen,
    {a => $COUNT, b => $COUNT, c => $COUNT, d => $COUNT, e => $COUNT},
    "Got all $COUNT messages from each process"
);

cleanup();
done_testing;
