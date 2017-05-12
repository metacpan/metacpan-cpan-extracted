# -*- Mode: Python -*-

# These are Pythonic ports of programs from MJD's HOP.

# Acme::Pythonic needs to know this prototype.
sub Iterator(&);

use Test::More 'no_plan';
use Acme::Pythonic debug => 0;

use strict
use warnings

my ($it, $computed, $expected)


#
# ---[ Chapter 1: Recursion ]-------------------------------------------
#

# This is hanoi() from page 9 plus a variation of check_move from pages
# 10 and 11 that constructs a list for testing instead of printing
# messages.

my @position = ('', ('A') x 3) # Disks are all initially on peg A

sub check_move:
    my $i
    my ($disk, $start, $end) = @_
    if $disk < 1 || $disk > $#position:
        die "Bad disk number $disk. Should be 1..$#position.\n"
    unless $position[$disk] eq $start:
        die "Tried to move disk $disk from $start, but it is on peg $position[$disk].\n"
    for $i in 1 .. $disk-1:
        if $position[$i] eq $start:
            die "Can't move disk $disk from $start because $i is on top of it.\n"
        elsif $position[$i] eq $end:
            die "Can't move disk $disk to $end because $i is already there.\n"
    push @$computed, [$disk, $start, $end]
    $position[$disk] = $end

sub hanoi:
    my ($n, $start, $end, $extra, $move_disk) = @_
    if $n == 1:
        $move_disk->(1, $start, $end)
    else:
        hanoi($n-1, $start, $extra, $end, $move_disk)
        $move_disk->($n, $start, $end)
        hanoi($n-1, $extra, $end, $start, $move_disk)

hanoi(3, 'A', 'C', 'B', \&check_move)
is_deeply($computed, [[1, 'A', 'C'],
                      [2, 'A', 'B'],
                      [1, 'C', 'B'],
                      [3, 'A', 'C'],
                      [1, 'B', 'A'],
                      [2, 'B', 'C'],
                      [1, 'A', 'C']])


#
# ---[ Chapter 4: Iterators ]-------------------------------------------
#

# Defined on page 121
sub upto:
    my ($mx, $nx) = @_
    return sub:
        return $mx <= $nx ? $mx++ : undef

$it = upto 2, 5
my $n = 2
while defined(my $val = $it->()):
    is $val, $n++
is $n, 6

# Defined on page 122
sub NEXTVAL:
    $_[0]->()

# Defined on page 123
sub Iterator(&):
    return $_[0]

# Defined on page 160
sub imap(&$):
    my ($transform, $it) = @_
    return Iterator:
        local $_ = NEXTVAL($it)
        return unless defined $_
        return $transform->()

$it = imap:
         $_ *= 2
         $_ += 1
         $_
      upto(2, 5)

$expected = [5, 7, 9, 11]
$computed = []
while my $val = NEXTVAL($it):
    push @$computed, $val
is_deeply $expected, $computed

# Defined on page 160
sub igrep(&$):
    my ($is_interesting, $it) = @_
    return Iterator:
        local $_
        while defined($_ = NEXTVAL($it)):
            return $_ if $is_interesting->()
        return

$it = igrep:
          $_ % 2
      upto(2, 11)
$expected = [3, 5, 7, 9, 11]
$computed = []
while my $val = NEXTVAL($it):
    push @$computed, $val
is_deeply $expected, $computed


# Defined on page 136
sub make_genes:
    my $pat = shift
    my @tokens = split /[()]/, $pat
    for my $i = 1; $i < @tokens; $i += 2:
        $tokens[$i] = [0, split(//, $tokens[$i])]
    my $FINISHED = 0
    return Iterator:
        return if $FINISHED
        my $finished_incrementing = 0
        my $result = ""
        for my $token in @tokens:
            if ref $token eq "":      # plain string
                $result .= $token
            else:                     # wildcard
                my ($n, @c) = @$token
                $result .= $c[$n]
                unless $finished_incrementing:
                    if $n == $#c:
                        $token->[0] = 0
                    else:
                        $token->[0]++
                        $finished_incrementing = 1
        $FINISHED = 1 unless $finished_incrementing
        return $result

my $seq = "A(CGT)CGT"
$expected = [qw(ACCGT AGCGT ATCGT)]
$computed = []
my $gene_iter = make_genes $seq
while my $g = NEXTVAL($gene_iter):
    push @$computed, $g
is_deeply($expected, $computed)

$seq = "A(CT)G(AC)"
$expected = [qw(ACGA ATGA ACGC ATGC)]
$computed = []
$gene_iter = make_genes $seq
while my $g = NEXTVAL($gene_iter):
    push @$computed, $g
is_deeply($expected, $computed)

$seq = "(abc)(de)-(12)"
$expected = [qw(ad-1 bd-1 cd-1 ae-1 be-1 ce-1 ad-2 bd-2 cd-2 ae-2 be-2 ce-2)]
$computed = []
$gene_iter = make_genes $seq
while my $g = NEXTVAL($gene_iter):
    push @$computed, $g
is_deeply($expected, $computed)


#
# --- [ Chapter 5: From Recursion to Iterators ] -----------------------
#

# Defined on page 210, with a fix for boundary conditions from page 211.
sub make_partitioner:
    my ($n, $treasures) = @_
    my @todo = $n ? [$n, $treasures, []] : [$n, [], []]
    sub:
        while @todo:
            my $cur = pop @todo
            my ($target, $pool, $share) = @$cur

            my ($first, @rest) = @$pool

            push @todo, [$target, \@rest, $share] if @rest
            if $target == $first:
                return [@$share, $first]
            elsif $target > $first && @rest:
                push @todo, [$target-$first, \@rest, [@$share, $first]]
        return undef

my $mp = make_partitioner(5, [1, 2])
$expected = []
$computed = []
while my $p = NEXTVAL($mp):
    push @$computed, $p
is_deeply($expected, $computed)

$mp = make_partitioner(5, [1, 2, 3])
$expected = [[2, 3]]
$computed = []
while my $p = NEXTVAL($mp):
    push @$computed, $p
is_deeply($expected, $computed)


# Defined on pages 252-253.
sub fib:
    my $n = shift
    my ($s1, $return)
    my $BRANCH = 0
    my @STACK
    while 1:
        if $n < 2:
            $return = $n
        else:
            if $BRANCH == 0:
                push (@STACK, [ 1, 0, $n ]), $n -= 1 while $n >= 2
                $return = $n
            elsif $BRANCH == 1:
                push @STACK, [ 2, $return, $n ]
                $n -= 2
                $BRANCH = 0
                next
            elsif $BRANCH == 2:
                $return += $s1

        return $return unless @STACK
        ($BRANCH, $s1, $n) = @{pop @STACK}

is fib(0), 0
is fib(1), 1
is fib(10), 55
is fib(21), 10946
