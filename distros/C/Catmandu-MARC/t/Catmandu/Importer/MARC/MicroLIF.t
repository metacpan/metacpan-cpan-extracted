#!perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Catmandu::Importer::MARC;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Importer::MARC::MicroLIF';
    use_ok $pkg;
}

require_ok $pkg;

my $importer = Catmandu::Importer::MARC->new( file => 't/sample1.lif', type => "MicroLIF" );

ok $importer , 'got an MARC/MicroLIF importer';

my @records;

my $n = $importer->each(
    sub {
        push( @records, $_[0] );
    }
);

ok(@records == 1);

ok($records[0]->{record}->[1]->[0] eq '008');

done_testing;
