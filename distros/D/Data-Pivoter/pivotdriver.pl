#!/usr/bin/perl

use strict;

use Data::Pivoter;
use Data::Dumper;
use lib "~/perl";


sub printout{
  my (@lines,$n,$m);
  @lines=@_;
  for ($n=0;$n<@lines;$n++){
    for ($m=0;$m<@{$lines[$n]};$m++){
      if (defined $lines[$n][$m]){
	print $lines[$n][$m],"\t";}
      else {print "\t";}
    }
    print "\n";
  }
}


my (@lines,$n,$m);
print "Loaded OK\n";
while(<>){
  next if /^\s*\n$/;
  chomp;
  @lines[$n++]=[split];
  print"[$n]\t$_\n";
}


print"\nOK\n";
#print Dumper(\@lines);
print "This should work:\n";
my $pivoter=Data::Pivoter->new(col=> 0, row=> 1, data=> 2);
printout( @{ $pivoter->pivot(\@lines)}); 
print "\n";

print "This should work with correctly sorted numbers:\n";
my $pivoter=Data::Pivoter->new(col=> 0, row=> 1, data=> 2, numeric=>'C');
printout( @{ $pivoter->pivot(\@lines)}); 
print "\n";

print "This should give a 'Definition Error:\n";
$pivoter=Data::Pivoter->new(col=> 0, row=> 1,);
printout(@{ $pivoter->pivot(\@lines)}); 
print "\n";

print "This should give a 'Definition Error:\n";
$pivoter=Data::Pivoter->new();
printout(@{$pivoter->pivot(\@lines)});
print"\n";

print "This should give a 'Definition Error:\n";
$pivoter=Data::Pivoter->new(col=> 1, row=> 1, data=> 2);
printout( @{$pivoter->pivot(\@lines)}); 
print"\n";

print "This should not give any errors, but a strange output (Diagonal matrix):\n";
$pivoter=Data::Pivoter->new(col=> 1, row=> 1, data=> 2, donotvalidate=>1);
printout( @{$pivoter->pivot(\@lines)}); 
print"\n";

print "This should work:\n";
$pivoter=Data::Pivoter->new('col', 2, 'row', 1,'group',0, 'data', 2);
printout( @{$pivoter->pivot(\@lines)}); 
print "\n";

# print "This should work in a later version:\n";
# $pivoter=Table::Pivot->new('col', 1, 'row', 0,'function','1', 'data', 2);
# printout( $pivoter->pivot(@lines)); 
# print "\n";
