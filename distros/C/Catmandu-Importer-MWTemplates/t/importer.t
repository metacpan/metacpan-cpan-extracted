use strict;
use warnings;
use Test::More;
use Catmandu -all;

use_ok 'Catmandu::Importer::MWTemplates';

foreach my $test (<t/*.wiki>) {
    $test =~ s/\.wiki$//;
    my $got    = importer('MWTemplates', file => "$test.wiki")->to_array;
    my $expect = importer('YAML', file => "$test.yaml")->to_array;
    exporter('YAML')->add_many($got);
    is_deeply $got, $expect, $test;
};

done_testing;
