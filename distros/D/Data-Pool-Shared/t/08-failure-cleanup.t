use strict;
use warnings;
use Test::More;
use Time::HiRes qw(alarm sleep time);
use POSIX qw(_exit WNOHANG);
use Data::Pool::Shared;

{
    package FailingValue;
    use overload
        '""' => sub { die $_[0][0] },
        '0+' => sub { die $_[0][0] },
        fallback => 1;
}
{
    package QuietException;
    use overload 'bool' => sub { 0 }, '""' => sub { '' }, fallback => 1;
}

for my $variant ('', qw(I64 I32 F64 Str)) {
    my $class = 'Data::Pool::Shared' . ($variant ? "::$variant" : '');
    my @width = !$variant || $variant eq 'Str' ? (16) : ();
    for my $method (qw(alloc_set try_alloc_set)) {
        my $p = $class->new(undef, 2, @width);
        my $keep = $p->alloc_set(7);
        for my $error ("conversion failed\n", bless([], 'QuietException')) {
            my $ok = eval { $p->$method(bless([$error], 'FailingValue')); 1 };
            ok !$ok, "$class $method propagates conversion failure";
            is $p->used, 1, 'failed write leaves no allocation behind';
            ok $p->is_allocated($keep), 'existing allocation retained';
        }
        {
            local $@ = "outer error\n";
            my $s = $p->$method(9);
            ok defined $s, 'slot reusable after failed writes';
            $p->free($s);
        }
        $p->free($keep);
    }
}

{
    package ValidatedPool;
    our @ISA = ('Data::Pool::Shared::I64');
    sub set {
        my ($self, $slot, $value) = @_;
        die "invalid value\n" if $value < 0;
        $self->SUPER::set($slot, $value + 1);
    }
}
for my $method (qw(alloc_set try_alloc_set)) {
    my $p = ValidatedPool->new(undef, 1);
    eval { $p->$method(-1) };
    is $p->used, 0, 'overridden setter failure releases slot';
    my $s = $p->$method(8);
    is $p->get($s), 9, 'overridden setter used on success';
    my @failed = $method eq 'alloc_set' ? $p->$method(8, 0) : $p->$method(8);
    is scalar @failed, 0, 'full pool preserves empty list return';
    $p->free($s);
}

{
    package NestedValue;
    use overload '0+' => sub {
        my ($p, $depth) = @{$_[0]};
        $p->alloc_set(bless([$p, $depth - 1], __PACKAGE__)) if $depth;
        die "nested conversion failed\n";
    }, fallback => 1;
}
{
    my $p = Data::Pool::Shared::I64->new(undef, 32);
    eval { $p->alloc_set(bless([$p, 16], 'NestedValue')) };
    is $p->used, 0, 'nested failed writes release every allocation';
}

{
    my $p = Data::Pool::Shared::I64->new(undef, 1);
    my $held = $p->alloc;
    local $SIG{ALRM} = sub {
        my @work = map { $_ * 2 } 1..4096;
        $p->free($held);
    };
    alarm(0.03);
    my $s = $p->alloc_set(11, 0.5);
    alarm(0);
    ok defined $s, 'signal handler can release a slot for alloc_set';
    is $p->get($s), 11, 'write succeeds after signal handler grows the Perl stack' if defined $s;
    is $p->stats->{waiters}, 0, 'signal-driven allocation leaves no waiter';
    $p->free($s) if defined $s;
}

for my $case (
    ['alloc',   [],      2],
    ['alloc',   [0.5],   2],
    ['alloc_n', [2],     1],
    ['alloc_n', [2, 0.5], 1],
) {
    my ($method, $args, $occupied) = @$case;
    my $p = Data::Pool::Shared::I64->new(undef, 2);
    my $held = $p->alloc_n($occupied);
    my $pid = fork // die "fork: $!";
    if (!$pid) {
        $SIG{ALRM} = sub { die "interrupted\n" };
        alarm(0.03);
        my $ok = eval { $p->$method(@$args); 1 };
        _exit(!$ok && $@ eq "interrupted\n" && !$p->stats->{timeouts} ? 0 : 1);
    }
    my $end = time + 3;
    my $done;
    while (time < $end) {
        $done = waitpid($pid, WNOHANG) == $pid;
        last if $done;
        sleep(0.01);
    }
    unless ($done) {
        kill 'KILL', $pid;
        waitpid($pid, 0);
    }
    is $?, 0, "$method dispatches signals while waiting";
    is $p->stats->{waiters}, 0, 'interrupted call leaves no waiter';
    is $p->used, $occupied, 'interrupted batch leaves no partial allocation';
    $p->free_n($held);
}

done_testing;
