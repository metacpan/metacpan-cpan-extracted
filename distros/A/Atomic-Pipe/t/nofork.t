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

my $alarm = 0;
$SIG{ALRM} = sub { $alarm++; die "ALARM\n" };
my $msg;
my $eval = eval {
    alarm 2;
    $msg = $p->read_message;
    alarm 0;
    1;
};
ok(!$eval, "Eval did not complete");
is($@, "ALARM\n", "Exception as expected");

is($msg, undef, "Did not read a message");
is($alarm, 1, "Did time out with alarm");

$p->blocking(0);
alarm 5;
is($p->read_message, undef, "No Message");
alarm 0;

is($w2->write_message("bb" x PIPE_BUF), 3, "Sent in 3 chunks");
is($p->read_message, ("bb" x PIPE_BUF), "Got message twice the pipe buffer length");

done_testing;
