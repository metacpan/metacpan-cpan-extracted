use inc::Module::Install;

# Define metadata
name        'AI-ExpertSystem-Advanced';
all_from    'lib/AI/ExpertSystem/Advanced.pm';

# Specific dependencies
requires    'Moose'             => '0.87';
requires    'YAML::Syck'        => '1.07';
requires    'List::MoreUtils'   => '0.22';
requires    'Class::Factory'    => '1.05';

no_index directory => 'examples';

repository 'http://github.com/pfischer/AI-ExpertSystem-Advanced';

WriteAll;



