# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

# Define metadata
name           'CSS-Moonfall';
all_from       'lib/CSS/Moonfall.pm';
githubmeta;

requires       'Text::Balanced' => '2.0.0';

auto_install;
WriteAll;

