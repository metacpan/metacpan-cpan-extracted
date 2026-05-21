use Test2::V0;
use Test2::IPC;
use Atomic::Pipe;

BEGIN { *PIPE_BUF = Atomic::Pipe->can('PIPE_BUF') }

use Fcntl;
use POSIX qw/mkfifo/;
use File::Temp qw/tempdir/;
use File::Spec;

BEGIN {
    my $path = __FILE__;
    $path =~ s{[^/]+\.t$}{select_mode.pm};
    require "./$path";
}

my $tempdir = tempdir(CLEANUP => 1);
my $fifo = File::Spec->catfile($tempdir, 'fifo');
unless (eval { mkfifo($fifo, 0700) or die "Failed to make fifo: $!" }) {
    die $@ unless $@ =~ m/not implemented on this architecture/;
    skip_all $@;
};

for my $use_select (io_select_modes()) {
    subtest "use_io_select=$use_select" => sub {
        my $r = Atomic::Pipe->read_fifo($fifo);
        my $w = Atomic::Pipe->write_fifo($fifo);

        $r->use_io_select($use_select);

        my $msg = "aaa\n";
        my $msg_len = length($msg);

        my $max_bytes = eval { fcntl($w->wh, Fcntl::F_GETPIPE_SZ(), 0) } // 16_384;
        my $atomic_bytes = PIPE_BUF();

        # Start with the atomic_byte count, multiplied by multiple message characters
        # means we exceed the atomic limit.
        my $count = $atomic_bytes;

        # If our total size would exceed the buffer size we need to back off a bit to
        # avoid blocking on write forever.
        $count-- while ($count * $msg_len) >= $max_bytes;

        note "Buffer Size:   $max_bytes\n";
        note "Atomic Size:   $atomic_bytes\n";
        note "Multiplier:    $msg_len\n";
        note "Multiple:      $count\n";
        note "Bytes to send: " . ($count * $msg_len) . "\n";

        $w->write_message("aaa\n" x $count);

        is(
            $r->read_message,
            "aaa\n" x $count,
            "Got message"
        );
    };
}

done_testing;
