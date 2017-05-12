use 5.010000;
use inc::Module::Install;

# Define metadata
name             'Date-Reformat';
all_from         'lib/Date/Reformat.pm';
readme_pod_from  'lib/Date/Reformat.pm';

# Specific dependencies
requires       'Types::Standard'=> '1.000005';
requires       'Type::Params'   => '1.000005';
test_requires  'Test::More'     => '0.88';
test_requires  'Test::Warnings' => '0.009';
auto_set_repository;

WriteAll;
