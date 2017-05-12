use inc::Module::Install 0.91;

if( -e 'MANIFEST.SKIP' ) {
    system( 'pod2text lib/DBIx/Class/Indexer/WebService/Solr.pm > README' );
}

perl_version '5.008';

name 'DBIx-Class-Indexer-WebService-Solr';
all_from 'lib/DBIx/Class/Indexer/WebService/Solr.pm';

requires 'DBIx::Class::Indexed';
requires 'WebService::Solr';
requires 'Scalar::Util';

test_requires 'Test::More';

repository "http://github.com/bricas/dbix-class-indexer-webservice-solr/tree/master";

WriteAll;
