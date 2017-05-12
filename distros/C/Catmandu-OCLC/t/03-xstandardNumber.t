#!/usr/bin/perl

use strict;
use warnings;
use warnings qw(FATAL utf8);
use utf8;
use Test::More;
use Catmandu::Fix;
use Data::Dumper;

my ($fixer,$record);

$fixer  = Catmandu::Fix->new(fixes => ['xID(my.test,xstandardNumber,getMetadata)']);
$record = $fixer->fix({ 'my' => { 'test' => '154684429'} }); 
is $record->{my}->{test}->{stat} , 'ok' , 'getMetadata';

$fixer  = Catmandu::Fix->new(fixes => ['xID(my.test,xstandardNumber,getEditions)']);
$record = $fixer->fix({ 'my' => { 'test' => '154684429'} }); 
is $record->{my}->{test}->{stat} , 'ok' , 'getVariants';

$fixer  = Catmandu::Fix->new(fixes => ['xID(my.test,xstandardNumber,getVariants)']);
$record = $fixer->fix({ 'my' => { 'test' => '154684429'} }); 
is $record->{my}->{test}->{stat} , 'ok' , 'getVariants';

done_testing 3;