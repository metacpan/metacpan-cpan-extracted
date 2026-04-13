#!/usr/bin/env perl
# Balanced parentheses checker using shared stack
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Data::Stack::Shared;
$| = 1;

my $stk = Data::Stack::Shared::Int->new(undef, 100);

my %match = (')' => '(', ']' => '[', '}' => '{');
my %open  = map { $_ => ord($_) } qw/( [ {/;
my %close = map { $_ => 1 } qw/) ] }/;

my @tests = (
    '((()))',
    '{[()]}',
    '((())',
    '([)]',
    '',
    '({[]})',
);

for my $expr (@tests) {
    $stk->clear;
    my $ok = 1;
    for my $ch (split //, $expr) {
        if ($open{$ch}) {
            $stk->push($open{$ch});
        } elsif ($close{$ch}) {
            my $top = $stk->pop;
            if (!defined $top || $top != ord($match{$ch})) {
                $ok = 0;
                last;
            }
        }
    }
    $ok = 0 if !$stk->is_empty;
    printf "%-10s %s\n", qq{"$expr"}, $ok ? "balanced" : "NOT balanced";
}
