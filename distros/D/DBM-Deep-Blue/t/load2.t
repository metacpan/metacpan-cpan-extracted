#!perl -w -I../lib -I../blib/arch 
use feature ':5.12';
use strict;
use warnings all=>'FATAL';

use Test::More;
use DBM::Deep::Blue;

#-----------------------------------------------------------------------
# Load a large structure and test retrieval of values in this structure.
#-----------------------------------------------------------------------

mkdir("memory");

my $m = DBM::Deep::Blue::file('memory/load.data');
my $h = $m->allocGlobalHash();

ok $h->{data}{"../images/images/street.PNG"}  {height} == 864;
ok $h->{data}{"../images/images/Ethiopia.PNG"}{objects}{toes}[1][3] eq "Square";
ok $h->{data}{"../images/images/appletree.PNG"}{objects}{"the back of the garden chair"}[0][0] == 198;

ok
   $h->{data}{"../images/images/Ethiopia.PNG"}{objects}{toes}[1][3]               
ne $h->{data}{"../images/images/appletree.PNG"}{objects}{"the back of the garden chair"}[0][0];

ok
   $h->{data}{"../images/images/appletree.PNG"}{objects}{"the back of the garden chair"}[0]
~~ $h->{DATA}{"../images/images/appletree.PNG"}{objects}{"the back of the garden chair"}[0];

   $h->{data}{"../images/images/appletree.PNG"}{objects}{"the back of the garden chair"}[0][0] =  100;
ok  
!( $h->{data}{"../images/images/appletree.PNG"}{objects}{"the back of the garden chair"}[0]
~~ $h->{DATA}{"../images/images/appletree.PNG"}{objects}{"the back of the garden chair"}[0]);
   $h->{data}{"../images/images/appletree.PNG"}{objects}{"the back of the garden chair"}[0][0] =  198;

ok
   $h->{data}{"../images/images/blocks.PNG"}{objects}{black}[0][3]
eq $h->{data}{"../images/images/Ethiopia.PNG"}{objects}{toes}[1][3];

 
done_testing;

