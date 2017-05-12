# Load the Module::Install bundled in ./inc/
use strict;
use inc::Module::Install;

my $from = 'lib/DBIx/Class/VirtualColumns.pm';

perl_version    '5.006';

# Define metadata
name            'DBIx-Class-VirtualColumns';
all_from        $from;
readme_from     $from;
readme_markdown_from $from;

# Specific dependencies
requires        'DBIx::Class'           => 0;

build_requires  'DBD::SQLite'           => 0;
build_requires  'Test::Pod'             => 0;
build_requires  'Test::Pod::Coverage'   => 0;
build_requires  'Class::C3'             => 0;

repository 'git://github.com/maros/DBIx-Class-VirtualColumns.git';

WriteAll;