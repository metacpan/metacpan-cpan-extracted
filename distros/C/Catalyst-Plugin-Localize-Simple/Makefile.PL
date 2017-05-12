use inc::Module::Install;

# Define metadata
name           'Catalyst-Plugin-Localize-Simple';
all_from       'lib/Catalyst/Plugin/Localize/Simple.pm';

# Specific dependencies
requires       'YAML'        => '0';
requires       'YAML::Syck'  => '0';

WriteAll;
