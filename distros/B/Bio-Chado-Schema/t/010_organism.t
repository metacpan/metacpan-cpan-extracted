#!/usr/bin/perl
use strict;
use warnings;

use FindBin;
use lib "$FindBin::RealBin/lib";
use Test::More;
use Test::Exception;
use Bio::Chado::Schema::Test;

my $schema = Bio::Chado::Schema::Test->init_schema();

isa_ok( $schema, 'DBIx::Class::Schema' );

my $organism = $schema->resultset('Organism::Organism');
isa_ok( $organism, 'DBIx::Class::ResultSet' );

lives_ok(
    sub {
        $organism
            ->get_column('organism_id')
            ->max()
    },
    'query into organism table lives'
);


my $org = $organism->create({
    abbreviation => 'T. testii',
    genus => 'Testus',
    species => 'testii',
    common_name => 'Test organism',
    comment => 'This is a test organism',
   });

like( $org->organism_id, qr/^\d+$/, 'inserted a new organism' );

is( $org->dbxrefs->count, 0, 'got no dbxrefs' );
is( $org->phylonodes->count, 0, 'got no phylonodes' );

$org->delete;

done_testing;
