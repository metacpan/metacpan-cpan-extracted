use strict;
use warnings;
use Test::More;
use Config;
use Data::TopK::Shared;

plan skip_all => 'fork required' unless $Config{d_fork};

# Argument magic (overload) that explicitly calls $obj->DESTROY frees the C
# handle mid-method.  Without the REEXTRACT guard the method would go on to
# dereference the freed handle and crash; with it the method must croak
# cleanly.  Each case runs in a forked child: exit 0 = croaked (correct),
# exit 7 = ran on through freed memory, signal = crash.

{
    package Evil;
    use overload
        '""' => sub { $_[0][0]->DESTROY; 'k' },
        '0+' => sub { $_[0][0]->DESTROY; 1 },
        fallback => 1;
}

my @cases = (
    [ add      => sub { my ($o, $e) = @_; $o->add($e) } ],
    [ add_many => sub { my ($o, $e) = @_; $o->add_many([$e]) } ],
    [ estimate => sub { my ($o, $e) = @_; $o->estimate($e) } ],
    [ top      => sub { my ($o, $e) = @_; $o->top($e) } ],
);

for my $case (@cases) {
    my ($method, $call) = @$case;
    my $pid = fork();
    unless ($pid) {
        my $tk = Data::TopK::Shared->new(undef, 8, 32);
        $tk->add('seed');            # non-empty segment for the readers
        my $evil = bless [$tk], 'Evil';
        my $ok = eval { $call->($tk, $evil); 1 };
        exit($ok ? 7 : 0);           # 0 = croaked (correct), 7 = ran on through freed memory
    }
    waitpid($pid, 0);
    my $st = $?;
    ok !($st & 127), "$method: no crash when argument magic destroys the handle"
        or diag sprintf('died with signal %d', $st & 127);
    is $st >> 8, 0, "$method: croaks instead of using the freed handle";
}

done_testing;
