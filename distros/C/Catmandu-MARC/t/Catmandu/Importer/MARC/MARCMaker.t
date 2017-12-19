#!perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Catmandu::Importer::MARC;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Importer::MARC::MARCMaker';
    use_ok $pkg;
}

require_ok $pkg;

my $importer = Catmandu::Importer::MARC->new(file => 't/camel.mrk', type => 'MARCMaker');

ok $importer , 'got an MARC/MARCMaker importer';

my $records = $importer->to_array;

ok(@$records == 10);

is($records->[0]->{record}->[1]->[4] , 'fol05731351 ');

is($records->[0]->{record}->[11]->[4] , 'Martinsson, Tobias,');

done_testing;
