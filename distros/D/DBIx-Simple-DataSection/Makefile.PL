use inc::Module::Install;
name 'DBIx-Simple-DataSection';
all_from 'lib/DBIx/Simple/DataSection.pm';

requires(
    'Data::Section::Simple' => 0,
    'DBIx::Simple'          => 0,
    'Carp'                  => 0,
);
test_requires( 
    'Test::More'  => 0.88,
);
use_test_base;
auto_include;
WriteAll;
