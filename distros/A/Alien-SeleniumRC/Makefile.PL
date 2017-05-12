use inc::Module::Install;

# Create the Makefile
name            'Alien-SeleniumRC';
all_from        'lib/Alien/SeleniumRC.pm';
build_requires  'Test::More'        => '0.42';
install_script  'bin/selenium-rc';

auto_install;
sign;
WriteAll;
