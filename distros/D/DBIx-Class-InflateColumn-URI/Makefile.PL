# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

# Define metadata
name 'DBIx-Class-InflateColumn-URI';
license 'perl';
perl_version '5.006001';
all_from 'lib/DBIx/Class/InflateColumn/URI.pm';

# Specific dependencies
requires 'URI'                      => 0;
requires 'DBIx::Class'              => 0.07005;
requires 'Class::Accessor::Grouped' => '0.03';

build_requires 'DBD::SQLite'              => '1.11';
build_requires 'Test::More'               => '0.42';
build_requires 'Test::Builder::Module'    => 0;
build_requires 'Class::Accessor::Grouped' => 0;
build_requires 'File::Spec::Functions'    => 0;

#recommends      'Your::OtherModule' => '0.01';

auto_install;
WriteAll;

