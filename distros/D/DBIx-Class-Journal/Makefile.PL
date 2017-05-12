use inc::Module::Install 0.89;
use strict;
use warnings;

use 5.008001;

# ****** DO NOT ADD OPTIONAL DEPENDENCIES. EVER. --mst ******

name     'DBIx-Class-Journal';
perl_version '5.008001';
all_from 'lib/DBIx/Class/Journal.pm';


test_requires 'Test::More'          => '0.94';
test_requires 'DBD::SQLite'         => '1.29';
test_requires 'SQL::Translator'     => '0.11003'; # we'll make this optional for release

requires 'DBIx::Class'              => '0.08115';
requires 'Class::C3::Componentised' => '1.0006';

tests_recursive ('t');

resources 'license'     => 'http://dev.perl.org/licenses/';
resources 'repository'  => 'http://github.com/dbsrgits/DBIx-Class-Journal';

WriteAll();

