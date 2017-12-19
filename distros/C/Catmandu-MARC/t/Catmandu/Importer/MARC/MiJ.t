#!perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Catmandu::Importer::MARC;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Importer::MARC::MiJ';
    use_ok $pkg;
}

require_ok $pkg;

my $importer = Catmandu::Importer::MARC->new(file => 't/test.ndj', type => 'MiJ');

ok $importer , 'got an MARC/MiJ importer';

my $records = $importer->to_array;

ok(@$records == 9);

is($records->[0]->{record}->[1]->[4] , '000000040');

is($records->[0]->{record}->[13]->[4] , 'Pevsner, Nikolaus,');

done_testing;
