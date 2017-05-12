#!/usr/bin/perl

print $/;
print " Changes should be made to Playground.tt *not* Playground.pm \n";
print " Changes should be made to MANIFEST.sans-scripts *not* MANIFEST \n";
print $/;

print $/;
print "I hope you bumped the version number", $/;
print $/;

#`cd scripts; ../delete-whitespace.pl; ../manifest-files.pl`;

my @system = qw(cvs commit);
system(@system) == 0 or die "system @system failed: $?";


`perl tt.pl Playground.tt`;
rename('Playground.tt-out', 'Playground.pm');
`pod2html Playground.pm > Playground.html`;

open M, ">MANIFEST";

open L, "MANIFEST.sans-scripts";
print M $_ while <L>;
print M $_, $/ while <scripts/*.pl>;

print `perl Makefile.PL PREFIX=$ENV{PREFIX}`;
print `make install`;
print `make tardist`;
