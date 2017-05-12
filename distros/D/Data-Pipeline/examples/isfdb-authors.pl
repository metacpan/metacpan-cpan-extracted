#! /usr/bin/perl

use lib '../lib';

use Data::Pipeline qw( Pipeline SPARQL Rename JSON Count );

use RDF::Core::Model;
use RDF::Core::Storage::Postgres;

my $model = RDF::Core::Model->new(
    Storage => RDF::Core::Storage::Postgres->new(
        ConnectStr => 'dbi:Pg:',
        Model => 4
    )
);

my $sparql = <<END;
PREFIX foaf: <http://xmlns.com/foaf/0.1/>
PREFIX dc:   <http://purl.org/dc/elements/1.1/>
PREFIX my: <http://isfdb.org/ns/>
SELECT ?label ?surname ?birth_place
WHERE {
        ?y dc:type "birth" .
        ?y my:place ?b .
        ?y my:person ?resource .
        ?resource foaf:name ?label .
        ?resource foaf:surname ?surname .
        ?b dc:title ?birth_place
}
END


my $json;

Pipeline(
    SPARQL( query => $sparql ), # input
    JSON # output
) -> from( model => $model ) 
  -> to( \$json );

print $json;
