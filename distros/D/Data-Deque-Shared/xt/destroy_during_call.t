use strict;
use warnings;
use Test::More;
use Config;
use POSIX qw(_exit);
use Data::Deque::Shared;

plan skip_all => 'AUTHOR_TESTING not set' unless $ENV{AUTHOR_TESTING};
plan skip_all => 'fork required' unless $Config{d_fork};

# Argument magic that explicitly calls $obj->DESTROY frees the C handle
# mid-method. Before the REEXTRACT fix the method dereferenced a freed
# pointer and SEGFAULTED; after it, the method must croak cleanly.
# This test FAILS (crash or exit 7) if the REEXTRACT calls are removed.

{
    package Evil;
    use overload
        '""' => sub { $_[0][0]->DESTROY; 'k' },
        '0+' => sub { $_[0][0]->DESTROY; 0.05 },
        fallback => 1;
}

my @cases = (
    [push_back      => sub { my ($dq, $evil) = @_; $dq->push_back($evil) }],
    [push_front     => sub { my ($dq, $evil) = @_; $dq->push_front($evil) }],
    [push_back_wait => sub { my ($dq, $evil) = @_; $dq->push_back_wait($evil, 0.05) }],
    [pop_front_wait => sub { my ($dq, $evil) = @_; $dq->pop_front_wait($evil) }],
);

for my $case (@cases) {
    my ($method, $call) = @$case;
    my $pid = fork() // die "fork: $!";
    if ($pid == 0) {
        my $dq   = Data::Deque::Shared::Str->new(undef, 8, 32);
        my $evil = bless [$dq], 'Evil';
        my $ok   = eval { $call->($dq, $evil); 1 };
        my $err  = $@ // '';
        # Exit 0 ONLY for the specific guard. Any OTHER death does not prove the
        # guard fired: free() does not unmap, so a stale read of h->elem_size
        # returns garbage that can trip an unrelated length check and croak --
        # which would make this test pass even with the fix removed.
        _exit($ok ? 7 : ($err =~ /destroyed during the call/ ? 0 : 8));
    }
    waitpid($pid, 0);
    my $st = $?;
    ok !($st & 127), "$method: no crash when argument magic destroys the handle"
        or diag sprintf('died with signal %d', $st & 127);
    is $st >> 8, 0, "$method: croaks via the destroyed-handle guard"
        or diag(($st >> 8) == 8 ? 'died, but not via the guard'
                                : 'returned through the freed handle');
}

done_testing;
