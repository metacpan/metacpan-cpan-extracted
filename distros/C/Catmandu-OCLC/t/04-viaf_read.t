#!/usr/bin/perl

use strict;
use warnings;
use warnings qw(FATAL utf8);
use utf8;
use Test::More;
use Catmandu::Fix;
use Data::Dumper;

my ($fixer,$record);

$fixer  = Catmandu::Fix->new(fixes => ['viaf_read(my.test)']);
$record = $fixer->fix({ 'my' => { 'test' => '102333412'} }); 

ok exists $record->{record} , 'viaf_read';

done_testing 1;