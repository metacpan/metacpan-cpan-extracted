use Test2::Require::Threads;
use threads;
use Test2::V0;
use Test2::IPC;
use Atomic::Pipe;
BEGIN { *PIPE_BUF = Atomic::Pipe->can('PIPE_BUF') }

my ($r, $w) = Atomic::Pipe->pair;

my @threads;
sub worker(&) {
    my ($code) = @_;
    push @threads => threads->create($code);
}

my $COUNT = 10_000;

worker { $w->write_message("aaa" x PIPE_BUF) for 1 .. $COUNT; $w->close };
worker { $w->write_message("bbb" x PIPE_BUF) for 1 .. $COUNT; $w->close };
worker { $w->write_message("ccc" x PIPE_BUF) for 1 .. $COUNT; $w->close };
worker { $w->write_message("ddd" x PIPE_BUF) for 1 .. $COUNT; $w->close };
worker { $w->write_message("eee" x PIPE_BUF) for 1 .. $COUNT; $w->close };

$w->close;

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
}

is(
    \%seen,
    {a => $COUNT, b => $COUNT, c => $COUNT, d => $COUNT, e => $COUNT},
    "Got all $COUNT messages from each thread"
);

$_->join for @threads;

done_testing;
