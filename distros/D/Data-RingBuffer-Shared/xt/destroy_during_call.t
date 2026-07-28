use strict;
use warnings;
use Test::More;
use Config;
use Data::RingBuffer::Shared;

# Argument magic that explicitly calls $obj->DESTROY frees the C handle
# mid-method.  Before the REEXTRACT fix the method dereferenced the freed
# pointer and SEGFAULTED; after it, the method must croak cleanly.  Each
# case runs in a forked child: exit 0 = croaked (correct), exit 7 = the
# method ran on through freed memory, a signal = crash.
plan skip_all => 'fork required' unless $Config{d_fork};

{
    package Evil;
    # latest() reads its $n argument via SvUV; wait_for() reads its $timeout
    # argument via SvNV.  Both are numeric conversions, so '0+' is the hook
    # that fires; '""' + fallback covers any string read.
    use overload
        '0+' => sub { $_[0][0]->DESTROY; 0 },
        '""' => sub { $_[0][0]->DESTROY; '0' },
        fallback => 1;
}

for my $case (qw(Int::latest F64::latest wait_for)) {
    my $pid = fork();
    die "fork failed: $!" unless defined $pid;
    if ($pid == 0) {
        my $obj;
        if ($case eq 'F64::latest') {
            $obj = Data::RingBuffer::Shared::F64->new(undef, 8);
            $obj->write(1.5);
        } else {
            $obj = Data::RingBuffer::Shared::Int->new(undef, 8);
            $obj->write(42) if $case eq 'Int::latest';
        }
        my $evil = bless [$obj], 'Evil';
        my $ok = eval {
            if ($case eq 'wait_for') {
                # count is 0 == expected, timeout numifies to 0: if the
                # method survived the freed handle it returns at once.
                $obj->wait_for(0, $evil);
            } else {
                $obj->latest($evil);
            }
            1;
        };
        exit($ok ? 7 : 0);   # 0 = croaked (correct), 7 = ran on through freed memory
    }
    waitpid($pid, 0);
    my $st = $?;
    ok !($st & 127), "$case: no crash when argument magic destroys the handle"
        or diag sprintf('died with signal %d', $st & 127);
    is $st >> 8, 0, "$case: croaks instead of using the freed handle";
}

done_testing;
