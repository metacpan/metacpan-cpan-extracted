#!/usr/bin/env perl
# Expression evaluator: shared stack for RPN (Reverse Polish Notation)
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Data::Stack::Shared;
$| = 1;

my $stk = Data::Stack::Shared::Int->new(undef, 100);

# evaluate RPN expression: 3 4 + 2 * 5 - = (3+4)*2-5 = 9
my @tokens = qw(3 4 + 2 * 5 -);

for my $tok (@tokens) {
    if ($tok =~ /^-?\d+$/) {
        $stk->push($tok);
        printf "push %d → [%s]\n", $tok, join(' ', reverse map { $stk->latest($_) } 0..$stk->size-1) if 0;
    } else {
        my $b = $stk->pop;
        my $a = $stk->pop;
        my $r;
        if    ($tok eq '+') { $r = $a + $b }
        elsif ($tok eq '-') { $r = $a - $b }
        elsif ($tok eq '*') { $r = $a * $b }
        elsif ($tok eq '/') { $r = int($a / $b) }
        $stk->push($r);
        printf "%d %s %d = %d\n", $a, $tok, $b, $r;
    }
}

printf "\nresult: %d\n", $stk->pop;
printf "stack empty: %s\n", $stk->is_empty ? "yes" : "no";
