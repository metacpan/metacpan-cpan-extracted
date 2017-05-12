#!/usr/bin/perl -X

use strict;
use warnings;
use AI::MicroStructure;
use Data::Printer;
use Data::Dumper;

my $h = AI::MicroStructure->new( 'germany', category => 'Dresden' );
my $h =  Dumper  $h->name();
p $h;



1;
