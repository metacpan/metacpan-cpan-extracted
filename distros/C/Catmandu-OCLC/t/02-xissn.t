#!/usr/bin/perl

use strict;
use warnings;
use warnings qw(FATAL utf8);
use utf8;
use Test::More;
use Catmandu::Fix;
use Data::Dumper;

my ($fixer,$record);

$fixer  = Catmandu::Fix->new(fixes => ['xID(my.test,xissn,getMetadata)']);
$record = $fixer->fix({ 'my' => { 'test' => '0036-8075'} }); 
is $record->{my}->{test}->{stat} , 'ok' , 'getMetadata';

$fixer  = Catmandu::Fix->new(fixes => ['xID(my.test,xissn,getEditions)']);
$record = $fixer->fix({ 'my' => { 'test' => '0036-8075'} }); 
is $record->{my}->{test}->{stat} , 'ok' , 'getEditions';

$fixer  = Catmandu::Fix->new(fixes => ['xID(my.test,xissn,getHistory)']);
$record = $fixer->fix({ 'my' => { 'test' => '0036-8075'} }); 
is $record->{my}->{test}->{stat} , 'ok' , 'getHistory';

$fixer  = Catmandu::Fix->new(fixes => ['xID(my.test,xissn,getForms)']);
$record = $fixer->fix({ 'my' => { 'test' => '0036-8075'} }); 
is $record->{my}->{test}->{stat} , 'ok' , 'getForms';

done_testing 4;