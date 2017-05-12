#! /usr/bin/perl
#
use strict;
use warnings;

use Test::More tests => 6;
use CracTools::Interval::Query;

my $intervalQuery = CracTools::Interval::Query->new();
my @results;

$intervalQuery->addInterval("a",1,12,1,"toto");
$intervalQuery->addInterval("a",5,14,1,"tata");
$intervalQuery->addInterval("b",5,14,1,"titi");
$intervalQuery->addInterval("b",2,2,1,"tonton");
$intervalQuery->addInterval("b",3,4,1,"tonton");

@results = @{$intervalQuery->fetchByRegion("a",12,15,1)};
is(@results,2,'fetchByRegion(1)');
is($results[0],"toto",'fetchByRegion(2)');
is($results[1],"tata",'fetchByRegion(3)');

@results = @{$intervalQuery->fetchByLocation("b",2,1)};
is(@results,1,'fetchByLocation(1)');
is($results[0],"tonton",'fetchByLocation(2)');

@results = @{$intervalQuery->fetchByLocation("b",1,1)};
is(@results,0,'fetchByLocation(1)');
