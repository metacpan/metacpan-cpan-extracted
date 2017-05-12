use inc::Module::Install 0.67;

if ( -e 'MANIFEST.SKIP' ) {
    system( 'pod2text lib/DBIx/Class/ResultSet/HashRef.pm > README' );
}

perl_version '5.006001';

name 'DBIx-Class-ResultSet-HashRef';
all_from 'lib/DBIx/Class/ResultSet/HashRef.pm';

requires 'DBIx::Class';

test_requires 'Test::More';

auto_install;
WriteAll;
