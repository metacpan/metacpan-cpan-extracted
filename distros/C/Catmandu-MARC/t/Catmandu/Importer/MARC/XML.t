#!perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Catmandu::Importer::MARC;
use utf8;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Importer::MARC::XML';
    use_ok $pkg;
}

require_ok $pkg;

my $importer = Catmandu::Importer::MARC->new(file => 't/marc.xml', type => 'XML');

ok $importer , 'got an MARC/XML importer';

my $records = $importer->to_array;

ok(@$records == 1);

is($records->[0]->{record}->[1]->[0] , '920');

is($records->[0]->{record}->[8]->[4] , 'TEEM (한국전기전자재료학회)');

# Test broken records
$importer = Catmandu::Importer::MARC->new(
    file => 't/broken.xml',
    type => "XML",
    skip_errors => 1,
);

ok $importer , 'got an MARC/XML importer';

$records = $importer->to_array();

ok (@$records == 9, 'skipped one record');

done_testing;
