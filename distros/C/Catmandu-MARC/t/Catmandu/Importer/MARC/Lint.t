#!perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Catmandu::Importer::MARC;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Importer::MARC::Lint';
    use_ok $pkg;
}

require_ok $pkg;

my $importer = Catmandu::Importer::MARC->new(
    file => 't/camel.mrc',
    type => "Lint"
);

ok $importer , 'got an MARC/ISO importer';

my $records = $importer->to_array();

ok @$records == 10, 'got all records' ;
is $records->[0]->{'_id'}             , 'fol05731351 ', 'got _id' ;
is $records->[0]->{'record'}->[1][-1] , 'fol05731351 ', 'got subfield' ;
is $records->[0]->{'_id'} , $records->[0]->{'record'}->[1][-1], '_id matches record id' ;

ok $records->[9]->{lint} , 'got lint';

like $records->[9]->{lint}->[0] , qr/Indicator 1 must be 0/ , 'got lit information';

done_testing;
