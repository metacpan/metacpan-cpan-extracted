use Test2::V0;
use Test2::IPC;
use Atomic::Pipe;

BEGIN { *PIPE_BUF = Atomic::Pipe->can('PIPE_BUF') }

BEGIN {
    my $path = __FILE__;
    $path =~ s{[^/]+\.t$}{worker.pm};
    require "./$path";
}

my ($r, $w) = Atomic::Pipe->pair;

my $COUNT = 10_000;

diag("Using count: $COUNT");

worker { $w->write_message("aaa" x PIPE_BUF) for 1 .. $COUNT };
worker { $w->write_message("bbb" x PIPE_BUF) for 1 .. $COUNT };
worker { $w->write_message("ccc" x PIPE_BUF) for 1 .. $COUNT };
worker { $w->write_message("ddd" x PIPE_BUF) for 1 .. $COUNT };
worker { $w->write_message("eee" x PIPE_BUF) for 1 .. $COUNT };

# Without this windows blocks in the main thread and the other threads never do their work.
sleep 2 if $^O eq 'MSWin32';

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
    "Got all $COUNT messages from each thread"
);

cleanup();

done_testing;
