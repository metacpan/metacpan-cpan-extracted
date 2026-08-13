use strict;
use warnings;
use Test::More;
use Config;
use POSIX ();
use Data::BitSet::Shared;

plan skip_all => 'fork required' unless $Config{d_fork};

# Adversarial re-entrancy coverage for the GAP1 identity guard in Shared.xs
# (EXTRACT_BS / REEXTRACT_BS).
#
# Every index/value argument on Data::BitSet::Shared's instance methods is a
# plain typemap UV: xsubpp converts it via SvUV in the INPUT section, which
# runs BEFORE PREINIT's EXTRACT_BS. So an overloaded argument's magic always
# fires *before* EXTRACT_BS re-reads the handle from self, not after -- there
# is no "extract, then convert, then use a stale h" window to close with a
# REEXTRACT_BS call here (unlike e.g. Data::Fenwick::Shared's merge() or
# Data::HashMap::Shared's key-taking methods, which manually convert a raw SV
# *after* extracting the handle, and Data::PerfectHash::Shared's has(), whose
# key type is only known at runtime). This is confirmed by direct comparison
# with the already-hardened Data::RoaringBitmap::Shared: its structurally
# identical add(self,x)/contains(self,x)/remove(self,x) get no REEXTRACT
# either.
#
# What the ordering *does* guarantee, and what this test verifies:
#
#  - destroy: magic that runs an explicit ->DESTROY on the invocant frees the
#    handle before EXTRACT_BS captures it. EXTRACT_BS's own null check must
#    then croak cleanly ("Attempted to use a destroyed ... object") rather
#    than let the XSUB dereference the freed handle.
#
#  - replace: magic that reassigns $victim to a *different*, live BitSet
#    object also runs before EXTRACT_BS captures anything, so EXTRACT_BS
#    simply captures a fresh, valid (if unintended) handle and the call
#    completes normally against the swapped object. That's a benign
#    confused-object quirk of Perl's @_ aliasing -- not a use-after-free --
#    and it must never crash.
#
# Each case runs in a forked child: any signal death (SIGSEGV/SIGBUS) is a
# crash the guard failed to prevent.

our $victim;

{
    package Evil::Destroy;
    use overload
        '0+' => sub { $_[0][0]->DESTROY; 1 },
        '""' => sub { $_[0][0]->DESTROY; '1' },
        fallback => 1;
}
{
    package Evil::Replace;
    use overload
        '0+' => sub { $main::victim = Data::BitSet::Shared->new(undef, 8); 3 },
        '""' => sub { $main::victim = Data::BitSet::Shared->new(undef, 8); '3' },
        fallback => 1;
}

my @methods = qw(set test clear toggle);

for my $method (@methods) {
    # -- destroy: must croak cleanly, naming the destroyed object --
    {
        my $pid = fork();
        die "fork: $!" unless defined $pid;
        unless ($pid) {
            $victim = Data::BitSet::Shared->new(undef, 64);
            my $evil = bless [$victim], 'Evil::Destroy';
            my $ok = eval { $victim->$method($evil); 1 };
            my $err = $@ // '';
            POSIX::_exit($ok ? 7 : ($err =~ /destroyed/i ? 0 : 8));
        }
        waitpid($pid, 0);
        my $st = $?;
        ok !($st & 127), "$method: no crash when argument magic destroys the handle"
            or diag sprintf('died with signal %d', $st & 127);
        is $st >> 8, 0, "$method: croaks cleanly instead of using the freed handle";
    }

    # -- replace: must never crash; silently operating on the swapped,
    # still-live object is accepted (not a use-after-free) --
    {
        my $pid = fork();
        die "fork: $!" unless defined $pid;
        unless ($pid) {
            $victim = Data::BitSet::Shared->new(undef, 64);
            my $evil = bless [$victim], 'Evil::Replace';
            eval { $victim->$method($evil) };
            POSIX::_exit(0);
        }
        waitpid($pid, 0);
        my $st = $?;
        ok !($st & 127), "$method: no crash when argument magic replaces the invocant"
            or diag sprintf('died with signal %d', $st & 127);
    }
}

done_testing;
