use Test2::V0;
use Test2::Require::RealFork;
use Test2::IPC;
use Atomic::Pipe;

BEGIN { *PIPE_BUF = Atomic::Pipe->can('PIPE_BUF') }

my ($r, $w) = Atomic::Pipe->pair;

print STDERR "\n";
print STDERR "Size: " . ($r->size || 'na') . "\n";
print STDERR "Buff: " . PIPE_BUF . "\n";

$SIG{CHLD} = 'IGNORE';
sub worker(&) {
    my ($code) = @_;
    my $pid = fork // die "Could not fork: $!";
    return $pid if $pid;

    my $ok = eval { $code->(); 1 };
    my $err = $@;
    exit(0) if $ok;
    warn $err;
    exit 255;
}

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

worker { is($w->write_message("aa" x PIPE_BUF), 3, "$$ Wrote 3 chunks") };
worker { is($w->write_message("bb" x PIPE_BUF), 3, "$$ Wrote 3 chunks") };
worker { is($w->write_message("cc" x PIPE_BUF), 3, "$$ Wrote 3 chunks") };

@messages = ();
push @messages => $r->read_message for 1 .. 3;

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
    $msg = $r->read_message;
    alarm 0;
    1;
};
ok(!$eval, "Eval did not complete");
is($@, "ALARM\n", "Exception as expected");

is($msg, undef, "Did not read a message");
is($alarm, 1, "Did time out with alarm");

$r->blocking(0);
alarm 5;
is($r->read_message, undef, "No Message");
alarm 0;

$w->write_message("aaa");
is($r->read_message, "aaa", "Got message in non-blocking mode");

done_testing;
