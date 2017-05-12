use inc::Module::Install 0.91;

if( -e 'MANIFEST.SKIP' ) {
    system( 'pod2text lib/Catalyst/Model/WebService/Lucene.pm > README' );
}

perl_version '5.008';

name 'Catalyst-Model-WebService-Lucene';
all_from 'lib/Catalyst/Model/WebService/Lucene.pm';

requires 'Catalyst::Runtime' => '5.7000';
requires 'WebService::Lucene';

test_requires 'Test::More';

WriteAll;
