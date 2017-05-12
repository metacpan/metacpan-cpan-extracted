# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

# Define metadata
name            'Blosxom-Include';
all_from        'Include.pm';

# Specific dependencies
requires         'Filter::Simple'       => 0;
requires         'FileHandle'           => 0;
build_requires   'Test::More'           => 0.42;
build_requires   'File::Basename'       => 0;
build_requires   'Cwd'                  => 0;

#recommends      'Your::OtherModule'    => '0.01';

#no_index        'directory'         => 'demos';

#install_script  'bin/myscript';

auto_install;
WriteAll;

