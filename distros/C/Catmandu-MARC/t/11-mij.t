#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use Catmandu::Importer::MARC;
use Test::More tests => 3;

my $importer = Catmandu::Importer::MARC->new(file => 't/test.ndj', type => 'MiJ');

my $records = $importer->to_array;

ok(@$records == 9);

is($records->[0]->{record}->[1]->[4] , '000000040');

is($records->[0]->{record}->[13]->[4] , 'Pevsner, Nikolaus,');

1;