use strict;
use warnings;
use Test::More;
use POSIX qw(_exit);
use Data::Stack::Shared;

# MPMC stress: multiple producers pushing, multiple consumers popping.
# Each pushed value is unique (pid<<20 | seq). The per-slot state machine
# must prevent torn reads where a pop races with a push on the same slot
# (the old lock-free design had this race; the state-machine gate closes it).

my $CAP       = 8;
my $PRODUCERS = 6;
my $CONSUMERS = 6;
my $PER_PROD  = 3000;

for my $variant (qw(Int Str)) {
    my $class = "Data::Stack::Shared::$variant";
    my @extra = $variant eq 'Str' ? (256) : ();
    my $stk     = $class->new(undef, $CAP, @extra);
    my $results = $class->new(undef, $PRODUCERS * $PER_PROD + 16, @extra);

    my @kids;
    for my $p (0 .. $PRODUCERS - 1) {
        my $pid = fork // die "fork: $!";
        if ($pid == 0) {
            my $base = ($p + 1) << 20;
            for my $i (1 .. $PER_PROD) {
                my $v = $base | $i;
                $v = pack('Q', $v) x 32 if $variant eq 'Str';
                $stk->push_wait($v, 30.0) or _exit(1);
            }
            _exit(0);
        }
        push @kids, $pid;
    }

    my $total   = $PRODUCERS * $PER_PROD;
    my $per_con = int($total / $CONSUMERS);
    my $extra   = $total - $per_con * $CONSUMERS;

    for my $c (0 .. $CONSUMERS - 1) {
        my $n = $per_con + ($c < $extra ? 1 : 0);
        my $pid = fork // die "fork: $!";
        if ($pid == 0) {
            for (1 .. $n) {
                if ($variant eq 'Str') {
                    my $peek = $stk->peek;
                    _exit(4) if defined($peek) && $peek ne pack('Q', unpack('Q', $peek)) x 32;
                }
                my $v = $stk->pop_wait(30.0);
                defined $v or _exit(2);
                $results->push_wait($v, 30.0) or _exit(3);
            }
            _exit(0);
        }
        push @kids, $pid;
    }

    for my $pid (@kids) {
        waitpid $pid, 0;
        ok $? == 0, "$variant worker $pid exit 0 (got $?)";
    }

    my %seen;
    my $dupes = 0;
    my $bogus = 0;
    while (defined(my $v = $results->pop)) {
        if ($variant eq 'Str') {
            my $id = unpack('Q', $v);
            $bogus++ if $v ne pack('Q', $id) x 32;
            $v = $id;
        }
        $dupes++ if $seen{$v}++;
        my $prod = $v >> 20;
        my $seq  = $v & 0xFFFFF;
        $bogus++ if $prod < 1 || $prod > $PRODUCERS || $seq < 1 || $seq > $PER_PROD;
    }

    is $dupes, 0, "$variant: no duplicate values popped (publication gate holds)";
    is $bogus, 0, "$variant: no torn/zeroed values popped";
    is scalar(keys %seen), $total, "$variant: all $total pushed values accounted for";
    ok $stk->is_empty, "$variant: stack drained";
}

done_testing;
