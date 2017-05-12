use inc::Module::Install 1.05;

if( -e 'MANIFEST.SKIP' ) {
    system( 'pod2text lib/DBIx/Class/DateTime/Epoch.pm > README' );
}

perl_version '5.006001';

name 'DBIx-Class-DateTime-Epoch';
all_from 'lib/DBIx/Class/DateTime/Epoch.pm';

requires 'DBIx::Class' => '0.08103'; # InflateColumn::DateTime overriding possible
requires 'DBIx::Class::TimeStamp' => '0.07'; # removes data_type checking
requires 'DateTime';

test_requires 'Test::More';
test_requires 'DBICx::TestDatabase';
test_requires 'DateTime::Format::SQLite';

repository 'http://github.com/bricas/dbix-class-datetime-epoch';

WriteAll;
