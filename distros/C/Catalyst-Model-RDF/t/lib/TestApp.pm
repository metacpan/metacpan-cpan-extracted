package # hide from PAUSE
    TestApp;

use strict;
use warnings;

use Catalyst;

__PACKAGE__->config(
    name        => 'TestApp',
    'Model::RDF' => {
        format     => 'rdfxml',
        namespaces => {
            rdf => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
            dct => 'http://purl.org/dc/terms/',
        },
        store      => {
            storetype => 'DBI',
            name      => 'test',
            dsn       => 'dbi:SQLite:dbname=test.sqlite',
            # to shut up the warnings
            username  => '',
            password  => '',
        },
    },
);

__PACKAGE__->setup;


1;
