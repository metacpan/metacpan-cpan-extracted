use strict;
use warnings;
use Test::More;
use Data::Queue::Shared;

# Randomized deque oracle: drive push/push_front/pop/pop_back against the Str
# queue and a plain Perl array in lockstep. A small arena relative to the item
# sizes forces frequent circular-arena wraps and waste, which is exactly the
# path where the old push_front (allocate-at-write-frontier, insert-at-head)
# corrupted live elements. Any arena mismatch surfaces as a wrong pop value.

my $CAP   = 16;     # element-count capacity
my $ARENA = 256;    # deliberately small -> many wraps

my $q = Data::Queue::Shared::Str->new(undef, $CAP, $ARENA);
my @oracle;         # front == $oracle[0], back == $oracle[-1]

# Deterministic LCG so a failure is reproducible.
my $seed = 0x1234abcd;
sub rnd { $seed = ($seed * 1103515245 + 12345) & 0x7fffffff; $seed }

my $counter = 0;
sub gen {
    my $pad = rnd() % 34;                       # 0..33 -> alloc spans several sizes
    sprintf("%d:", $counter++) . ("x" x $pad);
}

my $ops      = 40_000;
my $ok       = 1;
my $checked  = 0;

for my $i (1 .. $ops) {
    my $op = rnd() % 4;

    if ($op == 0) {                              # push_back
        my $s = gen();
        push @oracle, $s if $q->push($s);        # skip both if full (count/arena)
    }
    elsif ($op == 1) {                           # push_front
        my $s = gen();
        unshift @oracle, $s if $q->push_front($s);
    }
    elsif ($op == 2) {                           # pop_front
        my $got = $q->pop;
        my $exp = @oracle ? shift(@oracle) : undef;
        unless (eqv($got, $exp)) {
            $ok = 0;
            diag("pop_front mismatch at op $i: got=" . showv($got) . " exp=" . showv($exp));
            last;
        }
        $checked++;
    }
    else {                                       # pop_back
        my $got = $q->pop_back;
        my $exp = @oracle ? pop(@oracle) : undef;
        unless (eqv($got, $exp)) {
            $ok = 0;
            diag("pop_back mismatch at op $i: got=" . showv($got) . " exp=" . showv($exp));
            last;
        }
        $checked++;
    }

    if ($q->size != scalar @oracle) {
        $ok = 0;
        diag("size mismatch at op $i: queue=" . $q->size . " oracle=" . scalar(@oracle));
        last;
    }
}

ok($ok, "deque matches oracle across $ops random ops ($checked pops verified)");

# Drain whatever remains and confirm it matches front-to-back.
my @rest = $q->drain;
is_deeply(\@rest, \@oracle, "final drain matches oracle (" . scalar(@oracle) . " items)");

# Deterministic regression for the specific corruption: keep one element live
# at the low arena addresses, then cycle push_front + pop_front so the write
# frontier marches around the ring. Under the old allocate-at-write-frontier
# push_front, the wrap eventually memcpy'd a new element over the still-live
# KEEP element; popping it then returned the wrong bytes.
{
    my $q2 = Data::Queue::Shared::Str->new(undef, 16, 4096);  # 4096 = min arena
    my $KEEP = "K" x 200;
    $q2->push($KEEP);                       # KEEP occupies arena [0,200), stays front
    my $intact = 1;
    for my $c (1 .. 25) {                    # 25*200 > 4096 -> guaranteed wrap
        $q2->push_front("Y" x 200);
        my $y = $q2->pop;                    # pop the Y; KEEP remains the front
        $intact &&= (defined($y) && $y eq ("Y" x 200));
    }
    is($q2->pop, $KEEP, "wrapping push_front cycles do not corrupt a live element");
    ok($intact, "every cycled push_front/pop round-tripped intact");
}

sub eqv {
    my ($a, $b) = @_;
    return 1 if !defined($a) && !defined($b);
    return 0 if !defined($a) || !defined($b);
    return $a eq $b;
}
sub showv { defined $_[0] ? "'$_[0]'" : 'undef' }

done_testing;
