use Test2::Require::Threads;
use threads;
use Test2::V0;
use Test2::IPC;
use Atomic::Pipe;
BEGIN { *PIPE_BUF = Atomic::Pipe->can('PIPE_BUF') }

my $p = Atomic::Pipe->new;

print STDERR "\n";
print STDERR "Size: " . ($p->size || 'na') . "\n";
print STDERR "Buff: " . PIPE_BUF . "\n";

my @threads;
sub worker(&) {
    my ($code) = @_;
    push @threads => threads->create($code);
}

my $w = $p->clone_writer;

worker { $w->write_message("aaa") };
worker { $w->write_message("bbb") };
worker { $w->write_message("ccc") };

$p->reader;

my @messages;
push @messages => $p->read_message for 1 .. 3;

is(
    [sort @messages],
    [sort qw/aaa bbb ccc/],
    "Got all 3 short messages"
);

worker { is($w->write_message("aa" x PIPE_BUF), 3, threads->tid . " Wrote 3 chunks") };
worker { is($w->write_message("bb" x PIPE_BUF), 3, threads->tid . " Wrote 3 chunks") };
worker { is($w->write_message("cc" x PIPE_BUF), 3, threads->tid . " Wrote 3 chunks") };

@messages = ();
push @messages => $p->read_message for 1 .. 3;

is(
    [sort @messages],
    [sort(('aa' x PIPE_BUF), ('bb' x PIPE_BUF), ('cc' x PIPE_BUF))],
    "Got all 3 long messages, not mangled or mixed"
);

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

$w->write_message("aaa");
is($p->read_message, "aaa", "Got message in non-blocking mode");

$_->join for @threads;

done_testing;
