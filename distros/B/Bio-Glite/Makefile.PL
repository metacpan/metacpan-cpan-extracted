
# Load the Module::Install bundled in ./inc/
use inc::Module::Install;
    
# Define metadata
name            'Bio-Glite';
all_from        'lib/Bio/Glite.pm';
    
# Specific dependencies
requires        'Data::Dumper'          => '';
build_requires  'LWP::UserAgent'        => '';

#no_index        'directory'         => 'demos';
#install_script  'bin/myscript';
    
auto_install;
WriteAll;
