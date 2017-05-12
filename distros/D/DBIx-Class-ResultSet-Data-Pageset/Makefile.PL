use inc::Module::Install 0.91;

if ( -e 'MANIFEST.SKIP' ) {
    system( 'pod2text lib/DBIx/Class/ResultSet/Data/Pageset.pm > README' );
}

perl_version '5.006001';

name 'DBIx-Class-ResultSet-Data-Pageset';
all_from 'lib/DBIx/Class/ResultSet/Data/Pageset.pm';

requires 'Data::Pageset' => '1.02';
requires 'DBIx::Class';

test_requires 'Test::More';
test_requires 'File::Temp';

repository "http://github.com/bricas/dbix-class-resultset-data-pageset/tree/master";

WriteAll;
