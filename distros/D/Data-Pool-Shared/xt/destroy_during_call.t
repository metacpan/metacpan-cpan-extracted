use strict;
use warnings;
use Test::More;
use Config;
use POSIX ();
use Data::Pool::Shared;

plan skip_all => 'fork required' unless $Config{d_fork};

# Argument magic (overload) that explicitly DESTROYs the pool object whose
# C handle the method is about to use.  Before the REEXTRACT fix the method
# went on to dereference the freed handle (SEGV); after it the method must
# croak cleanly.  The child exits 0 when the method croaked, 7 when it ran
# on through the freed memory.

our $victim;

{
    package Evil;
    use overload
        '""' => sub { $_[0][0]->DESTROY; 'k' },
        '0+' => sub { $_[0][0]->DESTROY; 0 },
        fallback => 1;
}
{   # does not destroy anything -- just makes the invocant stop being a
    # reference, so an unguarded SvRV in REEXTRACT would read a non-ref.
    package Evil::Replace;
    use overload
        '""' => sub { $main::victim = 42; 'k' },
        '0+' => sub { $main::victim = 42; 0 },
        fallback => 1;
}

my $destroyed = qr/destroyed during the call/;
my $replaced  = qr/replaced during the call/;

# Note: XSUBs whose value argument is declared with a type (IV/UV/NV) have it
# converted by xsubpp in the INPUT section, BEFORE PREINIT/EXTRACT_POOL runs, so
# magic on those cannot dangle the handle. Only bare `SV *` arguments converted
# inside CODE can -- which is exactly what Raw set() and Str set() do.
my @cases = (
    [ 'alloc',      $destroyed, 'Evil',
      sub { my ($p, $e) = @_; $p->alloc($e) } ],                 # timeout arg, SvNV
    [ 'alloc_n',    $destroyed, 'Evil',
      sub { my ($p, $e) = @_; $p->alloc_n(2, $e) } ],            # timeout arg, SvNV
    [ 'free_n',     $destroyed, 'Evil',
      sub { my ($p, $e) = @_; $p->free_n([$e]) } ],              # array element, SvUV
    [ 'set (Raw)',  $destroyed, 'Evil',
      sub { my ($p, $e) = @_; my $s = $p->alloc; $p->set($s, $e) } ],
    # The invocant must be $main::victim ITSELF, not a lexical copy: the overload
    # replaces that package variable, and only then is the replaced SV the one
    # sitting in ST(0). Calling through a copied $p would exercise nothing.
    [ 'set (Raw), invocant replaced', $replaced, 'Evil::Replace',
      sub { my (undef, $e) = @_; my $s = $main::victim->alloc; $main::victim->set($s, $e) } ],
);

for my $case (@cases) {
    my ($method, $want, $evil_class, $call) = @$case;
    my $pid = fork();
    unless ($pid) {
        $victim = Data::Pool::Shared->new(undef, 10, 32);  # anonymous pool
        my $evil = bless [$victim], $evil_class;
        my $ok  = eval { $call->($victim, $evil); 1 };
        my $err = $@ // '';
        # exit 0 ONLY for the specific guard. Any OTHER death does not prove the
        # guard fired: free() does not unmap, so a stale read can trip an
        # unrelated check and croak, which would pass even with the fix removed.
        POSIX::_exit($ok ? 7 : ($err =~ $want ? 0 : 8));
    }
    waitpid($pid, 0);
    my $st = $?;
    ok !($st & 127), "$method: no crash when argument magic attacks the handle"
        or diag sprintf('died with signal %d', $st & 127);
    is $st >> 8, 0, "$method: croaks instead of using the bad handle";
}

# The Str variant has the same bare-SV set(); cover it too.
{
    my $pid = fork();
    unless ($pid) {
        $victim = Data::Pool::Shared::Str->new(undef, 10, 32);
        my $evil = bless [$victim], 'Evil';
        my $s    = $victim->alloc;
        my $ok   = eval { $victim->set($s, $evil); 1 };
        my $err  = $@ // '';
        POSIX::_exit($ok ? 7 : ($err =~ $destroyed ? 0 : 8));
    }
    waitpid($pid, 0);
    my $st = $?;
    ok !($st & 127), "set (Str): no crash when argument magic destroys the handle"
        or diag sprintf('died with signal %d', $st & 127);
    is $st >> 8, 0, "set (Str): croaks instead of using the freed handle";
}

done_testing;
