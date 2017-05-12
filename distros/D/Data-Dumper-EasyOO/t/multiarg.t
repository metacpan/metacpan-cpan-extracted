#!perl
# creates 1 EzDD, and alters it repeatedly, using both Set and AUTOLOAD

use strict;
use Test::More (tests => 11);
use vars qw($AR  $HR  @ARGold  @HRGold  @Arrays  @ArraysGold  @LArraysGold);
require 't/TestLabelled.pm';


use_ok qw(Data::Dumper);
use_ok qw(Data::Dumper::EasyOO);

my $ddez = Data::Dumper::EasyOO->new();
isa_ok ($ddez, 'Data::Dumper::EasyOO', "good DDEz object");

# this passes cuz array isnt (even length with scalars at odd indices)
is ($ddez->(@$AR), Dumper(@$AR), "odd length \@_");

# this is seen as labelled !!
isnt ($ddez->(%$HR), Dumper(%$HR), "\@HR seen as labeled !");

for my $a (0..$#Arrays) {
    is ($ddez->($Arrays[$a]), Dumper ($Arrays[$a]), "various arrays: $a");
}

is ($ddez->(@Arrays), Dumper (@Arrays), "array of arrays: 0..$#Arrays");

