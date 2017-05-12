use inc::Module::Install 0.91;

if( -e 'MANIFEST.SKIP' ) {
    system( 'pod2text lib/Catalyst/Model/WebService/Solr.pm > README' );
}

perl_version '5.008';

name 'Catalyst-Model-WebService-Solr';
all_from 'lib/Catalyst/Model/WebService/Solr.pm';

requires 'Catalyst::Runtime' => '5.7000';
requires 'Moose';
requires 'WebService::Solr';

test_requires 'Test::More';

WriteAll;
