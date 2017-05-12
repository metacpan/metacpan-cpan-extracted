use strict;
use warnings;
use Test::More;
use Catmandu::Importer::MWTemplates;

plan skip_all => 'Test disabled unless HTTP_TEST enabled'
    unless $ENV{HTTP_TEST};

my $importer = Catmandu::Importer::MWTemplates->new(
    site => 'de', page => 'Feminismus',
);

ok $importer->first;

done_testing;
