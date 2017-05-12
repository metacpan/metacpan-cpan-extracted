# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

# Define metadata
name            'DBIx-PgLink';
all_from        'lib/DBIx/PgLink.pm';

perl_version '5.008';

# Specific dependencies
requires 'Carp'             => 0;
requires 'Scalar::Util'     => 0;
requires 'Hash::Util'       => 0;
requires 'Data::Dumper'     => 0;
requires 'Cwd'              => 0;
requires 'DBI'              => '1.47';
requires 'Memoize'          => '1.01';
requires 'Tie::Cache::LRU'  => '0.21';
requires 'Moose'            => '0.33';
requires 'MooseX::Method'   => '0.39';
#requires 'MooseX::ClassAttribute' => '0.02';

build_requires 'Test::More'       => '0.7';
build_requires 'Test::Exception'  => '0.25';
build_requires 'Test::Deep'       => '0.096';
build_requires 'DBD::Pg'          => '1.47';
build_requires 'YAML'             => 0;

#recommends 'SQL::Statement' => '1.14';
#recommends 'DBIx::Safe'     => '1.2.5';

auto_install;
WriteAll;

