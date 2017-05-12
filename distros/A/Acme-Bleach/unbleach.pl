#! /usr/bin/perl -w

my $bleached = do{local $/;<>};
$bleached =~ s/(.*use\sAcme::Bleach\s*;[^\n]*\n)//xms;
my $preamble = $1;
my $tie = " \t"x8;
$bleached =~ s/^$tie|[^ \t]//g;
$bleached =~ tr/ \t/01/;
print $preamble, pack "b*", $bleached;
