#!/usr/bin/perl -w
use strict;
use warnings;
use ArrayHashSearch;

my $dummyarray1 = [1,2,3];
my $dummyarray2 = [4,5,$dummyarray1];
my $dummyarray3 = [7,$dummyarray2,9];
my $dummyhash1 = {1=>'a',2=>'b',3=>'c'};
my $dummyhash2 = {1=>$dummyhash1,2=>'d',3=>'e'};
my $dummyhash3 = {1=>'f',2=>'g',3=>$dummyhash2};
my $dummystructure1 = [1=>$dummyhash3,2=>$dummyarray3,3=>10];
my $dummystructure2 = {1=>'h',2=>$dummystructure1,3=>'i'};

print "ARRAY BINGO!\n" if array_deeply_contain($dummyarray3,5);
print "HASH BINGO!\n" if hash_deeply_contain($dummyhash3,'a');
print "ARRAY/HASH BINGO!\n" if deeply_contain($dummystructure1,5);
print "HASH/ARRAY BINGO!\n" if deeply_contain($dummystructure2,'a');


my $dummyarrayref = [1,3,7,11,13,17,19,23];
my $dummyarrayref2 = ['a','c','z',$dummyarrayref];

if (array_contain($dummyarrayref,7))
{
print "Value 7 exists in the array!\n";
}
if (array_deeply_contain($dummyarrayref2,7))
{
print "Value 7 exists in the array!\n";
}

