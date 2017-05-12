use inc::Module::Install 0.77;

if ( -e 'MANIFEST.SKIP' ) {
    system( 'pod2text lib/DBIx/Class/InflateColumn/Markup/Unified.pm > README' );
}

perl_version '5.008';

name 'DBIx-Class-InflateColumn-Markup-Unified';
all_from 'lib/DBIx/Class/InflateColumn/Markup/Unified.pm';

requires 'DBIx::Class' => 0.07005;
requires 'Markup::Unified';

test_requires 'Test::More';

auto_install;
WriteAll;
