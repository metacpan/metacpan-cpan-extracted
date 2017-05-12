#!/usr/bin/perl

use strict;
use warnings;
use warnings qw(FATAL utf8);
use utf8;
use Test::More;
use Catmandu::Fix;
use Data::Dumper;

my ($fixer,$record);

$fixer  = Catmandu::Fix->new(fixes => ['xID(my.test,xisbn,getMetadata)']);
$record = $fixer->fix({ 'my' => { 'test' => '0596002815'} }); 
is $record->{my}->{test}->{stat} , 'ok' , 'getMetadata';

$fixer  = Catmandu::Fix->new(fixes => ['xID(my.test,xisbn,getEditions)']);
$record = $fixer->fix({ 'my' => { 'test' => '0596002815'} }); 
is $record->{my}->{test}->{stat} , 'ok' , 'getEditions';

$fixer  = Catmandu::Fix->new(fixes => ['xID(my.test,xisbn,to13)']);
$record = $fixer->fix({ 'my' => { 'test' => '0596002815'} }); 
is $record->{my}->{test}->{stat} , 'ok' , 'to13';

$fixer  = Catmandu::Fix->new(fixes => ['xID(my.test,xisbn,to10)']);
$record = $fixer->fix({ 'my' => { 'test' => '0596002815'} }); 
is $record->{my}->{test}->{stat} , 'ok' , 'to10';

$fixer  = Catmandu::Fix->new(fixes => ['xID(my.test,xisbn,fixChecksum)']);
$record = $fixer->fix({ 'my' => { 'test' => '0596002815'} }); 
is $record->{my}->{test}->{stat} , 'ok' , 'fixChecksum';

$fixer  = Catmandu::Fix->new(fixes => ['xID(my.test,xisbn,hyphen)']);
$record = $fixer->fix({ 'my' => { 'test' => '0596002815'} }); 
is $record->{my}->{test}->{stat} , 'ok' , 'hyphen';

done_testing 6;