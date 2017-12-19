#!perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Catmandu::Importer::MARC;
use utf8;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Importer::MARC::RAW';
    use_ok $pkg;
}

require_ok $pkg;

my $importer = Catmandu::Importer::MARC->new(
    file => 't/dollar_subfields.mrc',
    type => "RAW"
);

ok $importer , 'got an MARC/RAW importer';

my $records = $importer->to_array();

ok( @$records == 2, 'got all records' );
is( $records->[0]->{'_id'}             , '12162', 'got _id' );


done_testing;
