use strict;
use DBIx::MyParsePP;
use DBIx::MyParsePP::Rule;
use DBIx::MyParsePP::Token;
use Data::Dumper;

my $parser = DBIx::MyParsePP->new();

print "Query is $ARGV[0]\n";
my $query = $parser->parse($ARGV[0]);

print "Expected:\n";
print Dumper $query->getExpected();

print "Actual:\n";
print Dumper $query->getActual();

print "Pos ".$query->pos()."; line: ".$query->line()."\n";

print "Tree:\n";
print Dumper $query->shrink();


