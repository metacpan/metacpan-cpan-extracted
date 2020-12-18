use Test2::V0;
use Atomic::Pipe;
BEGIN { *PIPE_BUF = Atomic::Pipe->can('PIPE_BUF') }

BEGIN {
    my $path = __FILE__;
    $path =~ s{[^/]+\.t$}{worker.pm};
    require "./$path";
}

my ($r, $w) = Atomic::Pipe->pair;

$r->blocking(1);
$w->blocking(0);

worker { note_sleep 10; while (my $msg = $r->read_message) { last if $msg =~ m/END/i } };

my $count = 0;
my $start = time;
until ($w->{out_buffer} && @{$w->{out_buffer}}) {
    $w->resize(PIPE_BUF * 2);    # Might not work, but nicer on systems where it does
    $w->write_message("aa" x PIPE_BUF);
    $count++;

    next unless $count > 1000;
    fail "Count got too high!";
    last;
}
ok(time - $start < 8, "Did not block");

$w->write_message("END");

# Clear the buffer
while (@{$w->{out_buffer}}) {
    $w->flush;
}

ok(1, "Was able to flush the buffer");

cleanup();

# Also checks the blocking flush on destroy
worker { sleep 1; $w->write_message("zz" x PIPE_BUF); do { $w = undef } };
my $msg = $r->read_message;
is($msg, "zz" x PIPE_BUF, "Got expected message when writing is non-blocking");

cleanup();

worker { note_sleep 10; while (my $msg = $r->read_message) { last if $msg =~ m/END/i } };

$w->blocking(1);

$start = time;
for ( 0 .. $count ) {
    $w->write_message("aa" x PIPE_BUF);
}
ok(time - $start > 5, "Blocked");

$w->write_message("END");

delete $w->{out_buffer};

cleanup();
done_testing;
