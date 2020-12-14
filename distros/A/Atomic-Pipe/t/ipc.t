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

worker { $w->write_message("aaa") };
worker { $w->write_message("bbb") };
worker { $w->write_message("ccc") };

my @messages;
push @messages => $r->read_message for 1 .. 3;

is(
    [sort @messages],
    [sort qw/aaa bbb ccc/],
    "Got all 3 short messages"
);

worker { $w->write_message("aa" x PIPE_BUF) };
worker { $w->write_message("bb" x PIPE_BUF) };
worker { $w->write_message("cc" x PIPE_BUF) };

sleep 2 if $^O eq 'MSWin32';

@messages = ();
push @messages => $r->read_message for 1 .. 3;

is(
    [sort @messages],
    [sort(('aa' x PIPE_BUF), ('bb' x PIPE_BUF), ('cc' x PIPE_BUF))],
    "Got all 3 long messages, not mangled or mixed"
);

cleanup();

worker { $w->write_message("dd" x PIPE_BUF) };

sleep 2 if $^O eq 'MSWin32';

is(
    $r->read_message(debug => 1),
    {
        message => ("dd" x PIPE_BUF),
        # We are testing that we got 3 parts
        parts => [2, 1 ,0],
        pid => D(),
        tid => D(),
    },
    "Got the pid, tid, message, and 3 parts were used"
);

cleanup();
done_testing;
