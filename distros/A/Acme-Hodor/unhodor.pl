#! /usr/bin/perl -w

my $hodored = do{local $/;<>};
$hodored =~ s/(.*use\sAcme::Hodor\s*;[^\n]*\n)//xms;
my $preamble = $1;
my $tie = "HODOR hodor hodor HODOR "x2;
$hodored =~ s/^$tie|[^HODOR hodor]//g;
$hodored =~ s/HODOR /0/g;
$hodored =~ s/hodor /1/g;
print $preamble, pack "b*", $hodored;
