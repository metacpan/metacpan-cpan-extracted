use strict;
use warnings;
use Test::More;
use Config;
use Data::PubSub::Shared;

plan skip_all => 'fork required' unless $Config{d_fork};

# Argument magic (tie/overload) runs arbitrary Perl between the method's
# EXTRACT_HANDLE/EXTRACT_SUB and its first use of the C pointer.  If that
# Perl calls $obj->DESTROY explicitly, the handle/subscriber is freed and
# the IV zeroed mid-method.  The REEXTRACT_* calls must re-read the IV and
# croak "... object destroyed during the call" instead of dereferencing
# the freed pointer.  Without them these cases segfault -- or, if the freed
# memory is still mapped, run on through it and exit 7.  Both are failures.

{
    package Evil;
    use overload
        '""' => sub { $_[0][0]->DESTROY; 'k' },
        '0+' => sub { $_[0][0]->DESTROY; 0 },
        fallback => 1;
}

my @cases = (
    ['Data::PubSub::Shared::Int::Sub::cursor' => sub {
        my $ps   = Data::PubSub::Shared::Int->new(undef, 32);
        my $sub  = $ps->subscribe;
        my $evil = bless [$sub], 'Evil';
        my $ok = eval { $sub->cursor($evil); 1 };
        exit($ok ? 7 : 0);   # 0 = croaked (correct), 7 = ran on through freed memory
    }],
    ['Data::PubSub::Shared::Int::Sub::drain' => sub {
        my $ps = Data::PubSub::Shared::Int->new(undef, 32);
        $ps->publish(1);     # non-empty so the drain loop body runs pre-fix
        my $sub  = $ps->subscribe_all;
        my $evil = bless [$sub], 'Evil';
        my $ok = eval { $sub->drain($evil); 1 };
        exit($ok ? 7 : 0);
    }],
    ['Data::PubSub::Shared::Int::Sub::poll_wait' => sub {
        my $ps   = Data::PubSub::Shared::Int->new(undef, 32);
        my $sub  = $ps->subscribe;
        my $evil = bless [$sub], 'Evil';
        my $ok = eval { $sub->poll_wait($evil); 1 };
        exit($ok ? 7 : 0);
    }],
    ['Data::PubSub::Shared::Str::publish' => sub {
        my $ps   = Data::PubSub::Shared::Str->new(undef, 32);
        my $evil = bless [$ps], 'Evil';
        my $ok = eval { $ps->publish($evil); 1 };
        exit($ok ? 7 : 0);
    }],
);

for my $case (@cases) {
    my ($method, $code) = @$case;
    my $pid = fork();
    unless ($pid) {
        $code->();
        exit 7;   # unreachable unless the child forgot to exit
    }
    waitpid($pid, 0);
    my $st = $?;
    ok !($st & 127), "$method: no crash when argument magic destroys the handle"
        or diag sprintf('died with signal %d', $st & 127);
    is $st >> 8, 0, "$method: croaks instead of using the freed handle";
}

done_testing;
