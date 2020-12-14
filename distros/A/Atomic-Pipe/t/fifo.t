use Test2::V0;
use Test2::IPC;
use Atomic::Pipe;

BEGIN { *PIPE_BUF = Atomic::Pipe->can('PIPE_BUF') }

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
my $w = Atomic::Pipe->write_fifo($fifo);

$w->write_message("aaa\n" x PIPE_BUF);

is(
    $r->read_message,
    "aaa\n" x PIPE_BUF,
    "Got message"
);

done_testing;
