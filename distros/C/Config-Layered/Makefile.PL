use inc::Module::Install;

name            'Config-Layered';
all_from        'lib/Config/Layered.pm';
license         'perl';

requires        'Getopt::Long'          => '0';
requires        'Config::Any'           => '0';


test_requires   'Test::More'            => '0.42';

WriteAll;
