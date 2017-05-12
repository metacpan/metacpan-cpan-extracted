use strict;
use inc::Module::Install;

name           'DBIx-MySQLSequence';
all_from       'lib/DBIx/MySQLSequence.pm';
requires       'DBI'             => 0;
requires       'DBD::mysql'      => 0;
requires       'Params::Util'    => '0.26';
build_requires 'Test::More'      => '0.47';
build_requires 'File::Spec'      => '0.80';

WriteAll;
