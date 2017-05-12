# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

# Define metadata
name            'App-Todo';
abstract_from   'lib/App/Todo.pm';
author          'Best Practical Solutions, LLC';
#version_from    'bin/todo.pl';
version_from    'lib/App/Todo.pm';

requires 'Encode';
requires 'YAML';
recommends 'YAML::Syck' => '0.71';
requires 'LWP::UserAgent';
requires 'Number::RecordLocator';
requires 'Getopt::Long';
requires 'Pod::Usage';
requires 'Email::Address';
requires 'Fcntl';
requires 'File::Temp';
requires 'Term::ReadKey';
requires 'Term::Encoding';

features(
    'Color output' => [
        -default => 1,
        recommends('Term::ANSIColor'),
        ( $^O eq 'MSWin32' ? recommends('Win32::Console::ANSI') : () )
    ]
);

install_script 'bin/todo.pl';
auto_install();
sign;
WriteAll;

