#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Data::Shared;

my $root = Data::Shared->new;
my $topk = eval { $root->mount('hits', 'topk', undef, 10) };
unless ($topk) {
    my $error = $@;
    die $error unless $error =~ /is not available; install the/;
}
print $topk ? "TopK: bounded estimates\n" : "TopK unavailable: exact counts\n";

# The fallback grows with distinct keys; a mounted TopK stays within its size.
# Anonymous root: neither branch outlives this process.
my %counts;
for my $key (qw(red blue red green red blue)) {
    if ($topk) { $root->set("/hits/$key") }
    else { $counts{$key}++ }
}
my @top = $topk ? $root->call('/hits', 'top', 3)
    : map { { key => $_, count => $counts{$_} } }
        sort { $counts{$b} <=> $counts{$a} || $a cmp $b } keys %counts;
printf "%s: %s%d\n", $_->{key}, $topk ? '~' : '', $_->{count} for @top;
