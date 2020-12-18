use Test2::V0;
use Atomic::Pipe;
BEGIN { *PIPE_BUF = Atomic::Pipe->can('PIPE_BUF') }

BEGIN {
    my $path = __FILE__;
    $path =~ s{[^/]+\.t$}{worker.pm};
    require "./$path";
}

my ($r, $w) = Atomic::Pipe->pair;

my $start = time;
worker { note_sleep 10; $w->write_message("aaa\n") };

sleep 2 if $^O eq 'MSWin32';

my $msg = $r->read_message;
ok(time - $start > 6, "Blocked");
is($msg, "aaa\n", "got the message");

cleanup();

$start = time;
worker { note_sleep 10; $w->write_message("bbb\n") };

sleep 2 if $^O eq 'MSWin32';

$r->blocking(0);

$msg = $r->read_message;
ok(time - $start < 8, "Did not spend too much time waiting");
ok(!$msg, "No message (did not block)");

cleanup();
done_testing;
