use inc::Module::Install;
name 'App-CLI-Plugin-Config-YAML-Syck';
author 'Akira Horimoto';
all_from 'lib/App/CLI/Plugin/Config/YAML/Syck.pm';

build_requires 'Test::More';
requires(
      "App::CLI::Extension" => 1.2,
      "YAML::Syck"          => 0,
    );
use_test_base;
auto_include;
author_tests('xt');
sign;
WriteAll;
