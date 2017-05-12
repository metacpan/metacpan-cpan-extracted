use inc::Module::Install;

name            'DBIx-Config';
all_from        'lib/DBIx/Config.pm';
license         'perl';

requires        'DBI'           => '0';
requires        'Config::Any'   => '0';
requires        'File::HomeDir' => '0';


test_requires   'Test::More'            => '0.42';
test_requires   'DBD::SQLite'           => '0';
test_requires   'Test::MockObject'      => '1.09';

WriteAll;
