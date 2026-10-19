use Test2::V0;
use Atomic::Pipe;

# A hard, non-retryable syswrite failure (EBADF) must throw, not retry
# forever. Build a pipe object whose write handle is really the read end
# of a pipe so every syswrite fails with EBADF.
pipe(my $rh, my $wh) or die "Could not create pipe: $!";
my $p = bless({wh => $rh}, 'Atomic::Pipe');

my @warnings;
local $SIG{__WARN__} = sub { push @warnings => @_ };

my $err = dies {
    local $SIG{ALRM} = sub { die "TIMEOUT - _write_burst hung in retry loop\n" };
    alarm 10;
    $p->write_burst("hello");
};
alarm 0;

ok($err, "hard syswrite error threw an exception");
unlike($err, qr/TIMEOUT/, "did not hang in the retry loop");
like($err, qr/invalid state/i, "pipe was marked invalid");

like(
    dies { $p->write_burst("again") },
    qr/invalid state/i,
    "pipe stays invalid after a hard write error"
);

done_testing;
