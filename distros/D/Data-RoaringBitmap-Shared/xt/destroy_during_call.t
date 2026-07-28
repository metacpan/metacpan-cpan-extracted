use strict;
use warnings;
use Test::More;
use Config;
use Data::RoaringBitmap::Shared;

plan skip_all => 'fork required' unless $Config{d_fork};

# Argument magic that explicitly calls $obj->DESTROY frees the C handle
# mid-method.  Before the REEXTRACT fix the method dereferenced the freed
# handle and SEGFAULTED; after it, the method must croak cleanly.  Each case
# runs in a forked child: exit 0 = croaked (correct), exit 7 = ran on through
# freed memory, signal = crash.
{
    package Evil;
    use overload
        '0+' => sub { $_[0][0]->DESTROY; 7 },
        '""' => sub { $_[0][0]->DESTROY; '7' },
        fallback => 1;
}

for my $method (qw(add_many)) {
    my $pid = fork();
    unless ($pid) {
        my $obj  = Data::RoaringBitmap::Shared->new(undef, 256);
        my $evil = bless [$obj], 'Evil';
        # add_many resolves each element with SvUV before locking; numifying
        # $evil destroys the handle out from under the already-EXTRACTed h.
        my $ok = eval { $obj->add_many([1, $evil, 2]); 1 };
        exit($ok ? 7 : 0);
    }
    waitpid($pid, 0);
    my $st = $?;
    ok !($st & 127), "$method: no crash when argument magic destroys the handle"
        or diag sprintf('died with signal %d', $st & 127);
    is $st >> 8, 0, "$method: croaks instead of using the freed handle";
}

done_testing;
