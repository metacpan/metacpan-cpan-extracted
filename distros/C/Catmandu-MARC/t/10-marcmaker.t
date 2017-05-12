#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use Catmandu::Importer::MARC;
use Test::More tests => 3;

my $importer = Catmandu::Importer::MARC->new(file => 't/camel.mrk', type => 'MARCMaker');

my $records = $importer->to_array;

ok(@$records == 10);

is($records->[0]->{record}->[1]->[4] , 'fol05731351 ');

is($records->[0]->{record}->[11]->[4] , 'Martinsson, Tobias,');

1;