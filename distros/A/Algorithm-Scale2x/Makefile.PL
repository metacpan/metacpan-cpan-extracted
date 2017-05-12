use inc::Module::Install 0.91;

if ( -e 'MANIFEST.SKIP' ) {
    system( 'pod2text lib/Algorithm/Scale2x.pm > README' );
}

perl_version '5.006';

name 'Algorithm-Scale2x';
all_from 'lib/Algorithm/Scale2x.pm';

test_requires 'Test::More';

WriteAll;
