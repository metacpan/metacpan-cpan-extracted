use Test::More;
use Test::Exception;

BEGIN
{
    eval { require IO::AIO; require AnyEvent::AIO; };
    plan skip_all => "IO::AIO and AnyEvent::AIO are required: $@" if $@;
}

plan tests => 4;

use_ok 'AnyEvent::Digest';

use AnyEvent;
use Digest::MD5;
use Symbol;

# See perldoc perlfork
# simulate open(FOO, "-|")
sub pipe_from_fork ($) {
    my $parent = shift;
    pipe $parent, my $child or die;
    my $pid = fork();
    die "fork() failed: $!" unless defined $pid;
    if ($pid) {
        close $child;
    }
    else {
        close $parent;
        close STDOUT; # Without this, Win32 may be blocked
        open(STDOUT, ">&=" . fileno($child)) or die;
    }
    $pid;
}

my $fh = gensym;
my $pid = pipe_from_fork($fh);
die if ! defined ($pid);
if(!$pid) {
    binmode STDOUT;
    print "\x0" x (1024 * 1024) for 1..512;
    exit;
}
#my $expected = $ref->addfile($fh)->hexdigest;
$expected = 'aa559b4e3523a6c931f08f4df52d58f2';

my $ref = Digest::MD5->new;
my $our;
lives_ok { $our = AnyEvent::Digest->new('Digest::MD5', backend => 'aio') } 'construction';

my $interval = $ENV{TEST_ANYEVENT_DIGEST_INTERVAL} || 0.01;
my $count = 0;
my $w; $w = AE::timer 0, $interval, sub {
    ++$count;
};

my $cv = AE::cv;
$our->addfile_async($fh)->cb(sub {
    is($expected, shift->recv->hexdigest, 'add -> digest');
    ok($count > 0);
    diag("$interval interval: $count count");
    undef $w;
    $cv->send;
});

$cv->recv;

