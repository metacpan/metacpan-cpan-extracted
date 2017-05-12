# Load the Module::Install bundled in ./inc/
use strict;
use inc::Module::Install;

my $from = 'lib/DBIx/Class/DeleteAction.pm';

# Define metadata
name            'DBIx-Class-DeleteAction';
all_from        $from;
readme_from     $from;
readme_markdown_from $from;

perl_version    '5.006';

# Specific dependencies
requires        'DBIx::Class'           => 0;
requires        'SQL::Abstract'         => 0;
requires        'version'               => 0;

build_requires  'DBD::SQLite'           => 0;
build_requires  'Test::Pod'             => 0;
build_requires  'Test::Pod::Coverage'   => 0;
build_requires  'Class::C3'             => 0;
build_requires  'Test::Exception'       => 0;
build_requires  'Test::Warn'            => 0;

repository "git://github.com/maros/DBIx-Class-DeleteAction.git";


WriteAll;