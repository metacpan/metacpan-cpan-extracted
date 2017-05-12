use inc::Module::Install;
name 'DBIx-RewriteDSN';
all_from 'lib/DBIx/RewriteDSN.pm';

requires $_ for (qw/ DBI File::Slurp /);

test_requires 'Test::More';
# test_requires 'DBD::SQLite';

use_test_base;
auto_include;
WriteAll;
