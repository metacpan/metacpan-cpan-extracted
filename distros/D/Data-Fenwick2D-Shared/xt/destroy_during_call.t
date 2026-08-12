use strict;
use warnings;
use Test::More;
use Config;
use POSIX ();
use Data::Fenwick2D::Shared;

plan skip_all => 'fork required' unless $Config{d_fork};

# Adversarial re-entrancy coverage for the GAP1 identity guard in Shared.xs
# (EXTRACT / REEXTRACT).
#
# Every coordinate/value argument on Data::Fenwick2D::Shared's instance
# methods (x, y, x1/y1/x2/y2, delta, value) is a plain typemap UV/IV: xsubpp
# converts it via SvUV/SvIV in the INPUT section, which runs BEFORE PREINIT's
# EXTRACT. So an overloaded argument's magic always fires *before* EXTRACT
# re-reads the handle from self, not after -- there is no "extract, then
# convert, then use a stale h" window to close with a REEXTRACT call here
# (unlike e.g. Data::Fenwick::Shared's merge(), which manually extracts a
# second SV after EXTRACT). This is confirmed both by inspecting the
# generated Shared.c (x/y/delta are SvUV/SvIV'd before EXTRACT executes) and
# by direct comparison with Data::Fenwick::Shared, this module's 1D analog:
# its structurally identical update/set/prefix/range/point get no REEXTRACT
# either.
#
# What the ordering *does* guarantee, and what this test verifies, for each
# of update/set/prefix/rect/point:
#
#  - destroy: magic that runs an explicit ->DESTROY on the invocant frees the
#    handle before EXTRACT captures it. EXTRACT's own null check must then
#    croak cleanly ("Attempted to use a destroyed ... object") rather than
#    let the XSUB lock or dereference the freed handle.
#
#  - replace: magic that reassigns $victim to a *different*, live Fenwick2D
#    object also runs before EXTRACT captures anything, so EXTRACT simply
#    captures a fresh, valid (if unintended) handle and the call completes
#    normally against the swapped object. That's a benign confused-object
#    quirk of Perl's @_ aliasing -- not a use-after-free -- and it must never
#    crash or deadlock.
#
# Each case runs in a forked child: any signal death (SIGSEGV/SIGBUS/SIGABRT)
# is a crash the guard failed to prevent.

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
        '0+' => sub { $main::victim = Data::Fenwick2D::Shared->new(undef, 8, 8); 1 },
        '""' => sub { $main::victim = Data::Fenwick2D::Shared->new(undef, 8, 8); '1' },
        fallback => 1;
}

# method => extra args passed after the tied/overloaded coordinate (which
# always stands in for the method's first coordinate argument, x or x1).
my %methods = (
    update => [1, 5],     # update(x, y, delta)
    set    => [1, 5],     # set(x, y, value)
    prefix => [1],        # prefix(x, y)
    rect   => [1, 2, 2],  # rect(x1, y1, x2, y2)
    point  => [1],        # point(x, y)
);

for my $method (sort keys %methods) {
    my @extra = @{ $methods{$method} };

    # -- destroy: must croak cleanly, naming the destroyed object --
    {
        my $pid = fork();
        die "fork: $!" unless defined $pid;
        unless ($pid) {
            $victim = Data::Fenwick2D::Shared->new(undef, 8, 8);
            my $evil = bless [$victim], 'Evil::Destroy';
            my $ok = eval { $victim->$method($evil, @extra); 1 };
            my $err = $@ // '';
            POSIX::_exit($ok ? 7 : ($err =~ /destroyed/i ? 0 : 8));
        }
        waitpid($pid, 0);
        my $st = $?;
        ok !($st & 127), "$method: no crash when argument magic destroys the handle"
            or diag sprintf('died with signal %d', $st & 127);
        is $st >> 8, 0, "$method: croaks cleanly instead of using the freed handle";
    }

    # -- replace: must never crash or deadlock; silently operating on the
    # swapped, still-live object is accepted (not a use-after-free) --
    {
        my $pid = fork();
        die "fork: $!" unless defined $pid;
        unless ($pid) {
            $victim = Data::Fenwick2D::Shared->new(undef, 8, 8);
            my $evil = bless [$victim], 'Evil::Replace';
            eval { $victim->$method($evil, @extra) };
            POSIX::_exit(0);
        }
        waitpid($pid, 0);
        my $st = $?;
        ok !($st & 127), "$method: no crash when argument magic replaces the invocant"
            or diag sprintf('died with signal %d', $st & 127);
    }
}

done_testing;
