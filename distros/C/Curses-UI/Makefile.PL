# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

# Define metadata
name            'Curses-UI';
all_from        'lib/Curses/UI.pm';

# Specific dependencies
requires        'Curses'        => 0;
requires        'Term::ReadKey' => 0;

no_index        'directory'         => 'examples';

auto_install;
WriteAll;
