#!/usr/bin/perl
use strict;
use Acme::Tests::Perl;
use Test::More 'no_plan';

my $t = Acme::Tests::Perl->new;
my @questions;
my @answers;
while(my $q = $t->next_question) {
    print STDERR "\b\n$q\n==> ";
    my $a = <>;
    push @questions,$q;
    push @answers,$a;
}

print STDERR "Verifing your answer...\n";
for(0..$#questions) {
    ok( $t->is_correct($questions[$_],$answers[$_]) )
}
