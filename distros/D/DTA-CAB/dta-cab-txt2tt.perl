#!/usr/bin/perl -w

local $/=undef;
my $buf = <>;
$buf =~ s/\r?\n\t\+?/\t/sg;
print $buf;

