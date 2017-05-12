use inc::Module::Install;
name 'App-CLI-Plugin-Log-Dispatch-Configurator-YAML';
all_from 'lib/App/CLI/Plugin/Log/Dispatch/Configurator/YAML.pm';

requires(
    "App::CLI::Extension" => 1.4,
    "Log::Dispatch::Config" => 0,
    "Log::Dispatch::Configurator::YAML" => 0,
    "Class::Accessor::Grouped" => 0
);

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
auto_set_repository;
auto_include;
WriteAll;
