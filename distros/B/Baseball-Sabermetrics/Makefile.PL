# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

# Define metadata
name            'Baseball-Sabermetrics';
all_from        'lib/Baseball/Sabermetrics.pm';

# Specific dependencies
#requires        'Carp'              => 0;
build_requires  'Test::More'        => '0.42';
recommends      'LWP::UserAgent'    => '2.33',
                'HTML::TableExtract'=> '2.08',
		'Data::Serializer'  => '0.29';

no_index        'directory'         => 'examples';

auto_install;
WriteAll;
