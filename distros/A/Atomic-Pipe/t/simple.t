use Test2::V0;
use Atomic::Pipe;
BEGIN { *PIPE_BUF = Atomic::Pipe->can('PIPE_BUF') }

my $p = Atomic::Pipe->new;

my $w1 = $p->clone_writer;
my $w2 = $p->clone_writer;
my $w3 = $p->clone_writer;

$p->reader;

$w1->write_message("aaa");
$w2->write_message("bbb");
$w3->write_message("ccc");

is($p->read_message, "aaa", "Got first message");
is($p->read_message, "bbb", "Got second message");
is($p->read_message, "ccc", "Got third message");

done_testing;
