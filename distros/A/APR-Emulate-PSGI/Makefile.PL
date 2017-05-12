use 5.010000;
use inc::Module::Install;

# Define metadata
name             'APR-Emulate-PSGI';
all_from         'lib/APR/Emulate/PSGI.pm';
readme_pod_from  'lib/APR/Emulate/PSGI.pm';

# Specific dependencies
requires       'URI'           => '0';
requires       'HTTP::Headers' => '0';
test_requires  'Test::More'    => '0.88';
test_requires  'IO::File'      => '0';
auto_set_repository;

WriteAll;
