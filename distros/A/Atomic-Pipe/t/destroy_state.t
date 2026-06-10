use Test2::V0;
use Atomic::Pipe;
use Errno qw/ENOENT/;

# DESTROY may flush buffered output (syswrite etc). That must not clobber
# the caller's error variables at scope exit.

my ($r, $w) = Atomic::Pipe->pair;
$w->write_blocking(0);
$r->read_blocking(0);

my $n = 0;
until ($w->pending_output) {
    $w->write_burst("x" x 64) or die "burst too big";
    die "pipe never filled" if ++$n > 1_000_000;
}

# Drain so the flush in DESTROY succeeds (successful syswrite resets $! to 0).
while ($r->fill_buffer) { }
delete $r->{in_buffer};
$r->{in_buffer_size} = 0;

$! = ENOENT;
$@ = "precious";
$? = 42 << 8;

undef $w;

is(0 + $!, ENOENT,   'DESTROY preserved $!');
is($@,     "precious", 'DESTROY preserved $@');
is($?,     42 << 8,  'DESTROY preserved $?');

done_testing;
