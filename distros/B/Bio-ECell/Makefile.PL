# Load the Module::Install bundled in ./inc/
use inc::Module::Install;
    
# Define metadata
name            'Bio-ECell';
all_from        'lib/Bio/ECell.pm';
    
    # Specific dependencies
requires        'Inline::Python'    => '0.20';
build_requires  'Test::More'        => '0.42';
    
#no_index        'directory'         => 'demos';
#install_script  'bin/myscript';
    
auto_install;
WriteAll;
