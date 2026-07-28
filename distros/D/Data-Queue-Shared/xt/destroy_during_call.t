use strict;
use warnings;
use Test::More;
use Config;
use Data::Queue::Shared;

plan skip_all => 'fork required' unless $Config{d_fork};

# Argument magic that explicitly calls $obj->DESTROY frees the C handle
# mid-method.  Before the REEXTRACT fix the method dereferenced a freed
# pointer and SEGFAULTED; after it, the method must croak cleanly.
# Exit codes in the child: 0 = croaked (correct), 7 = ran on through
# freed memory (REEXTRACT missing).  A signal death also fails.

{
    package Evil;
    use overload
        '""' => sub { $_[0][0]->DESTROY; 'k' },
        '0+' => sub { $_[0][0]->DESTROY; 0 },
        fallback => 1;
}

my @cases = (
    # name            constructor + call, run entirely in the child
    [ 'Str::push', sub {
        my $q = Data::Queue::Shared::Str->new(undef, 16);
        my $evil = bless [$q], 'Evil';
        $q->push($evil);
    } ],
    [ 'Str::push_front', sub {
        my $q = Data::Queue::Shared::Str->new(undef, 16);
        my $evil = bless [$q], 'Evil';
        $q->push_front($evil);
    } ],
    [ 'Str::push_wait', sub {
        my $q = Data::Queue::Shared::Str->new(undef, 16);
        my $evil = bless [$q], 'Evil';
        $q->push_wait($evil, 0);
    } ],
    [ 'Int::push_multi', sub {
        my $q = Data::Queue::Shared::Int->new(undef, 16);
        my $evil = bless [$q], 'Evil';
        $q->push_multi($evil);
    } ],
);

for my $case (@cases) {
    my ($method, $run) = @$case;
    my $pid = fork();
    unless ($pid) {
        my $ok = eval { $run->(); 1 };
        exit($ok ? 7 : 0);
    }
    waitpid($pid, 0);
    my $st = $?;
    ok !($st & 127), "$method: no crash when argument magic destroys the handle"
        or diag sprintf('died with signal %d', $st & 127);
    is $st >> 8, 0, "$method: croaks instead of using the freed handle";
}

done_testing;
