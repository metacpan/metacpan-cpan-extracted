# Load the Module::Install bundled in ./inc/
use inc::Module::Install;
    
# Define metadata
name            'Data-Ovulation';
all_from        'lib/Data/Ovulation.pm';
    
# Specific dependencies
requires        'Carp'              => '1.00';
requires        'Class::Accessor'   => '0.30';
requires        'Exporter'          => '5.00';
build_requires  'Test::More'        => '0.42';
    
no_index        'directory'         => 'examples';
    
auto_install;
WriteAll;
