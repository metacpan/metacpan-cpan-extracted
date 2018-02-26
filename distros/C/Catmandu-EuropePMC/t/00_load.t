use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Exception;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Importer::EuropePMC';
    use_ok $pkg;
}

require_ok $pkg;

my $network_test = $ENV{NETWORK_TEST} || "";

dies_ok {$pkg->new(module => 'search')} "required argument missing";

dies_ok { $pkg->new(module => "databaseLinks", page => 1) } "required argument missing";

lives_ok { $pkg->new(query => "malaria") } "required argument ok";

lives_ok { $pkg->new(query => "malaria", raw => 1) } "raw xml ok";

lives_ok { $pkg->new(pmid => "10779411") } "required argument ok";

my $importer = $pkg->new(query => '10779411');

isa_ok($importer, $pkg);

can_ok($importer, 'each');

can_ok($importer, 'count');

SKIP: {
    skip "No NETWORK_TEST env variable set.", 1 unless $network_test;

    lives_ok { $pkg->new(
            query => '10779411',
            module => 'citations',
            page => '2',
            ) } "ok for citations";

    lives_ok { $pkg->new(
            query => '10779411',
            module => 'references',
            page => '3',
            ) } "ok for references";

    lives_ok { $pkg->new(
    		query => '10779411',
    		module => 'databaseLinks',
    		db => 'uniprot',
    		page => '1',
    		) } "ok for databaseLinks";

}

done_testing;
