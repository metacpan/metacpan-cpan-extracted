use inc::Module::Install 0.91;

if ( -e 'MANIFEST.SKIP' ) {
    system( 'pod2text lib/Catalyst/Model/Gedcom.pm > README' );
}

name 'Catalyst-Model-Gedcom';
perl_version '5.008001';
all_from 'lib/Catalyst/Model/Gedcom.pm';

requires 'Gedcom';

test_requires 'Test::More';

repository "http://github.com/bricas/catalyst-model-gedcom/tree/master";

WriteAll;
