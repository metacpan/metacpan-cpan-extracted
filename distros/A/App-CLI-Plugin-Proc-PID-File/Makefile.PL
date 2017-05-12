use inc::Module::Install;
name 'App-CLI-Plugin-Proc-PID-File';
author 'Akira Horimoto';
all_from 'lib/App/CLI/Plugin/Proc/PID/File.pm';

build_requires 'Test::More';
requires(
      "App::CLI::Extension"      => 1.4,
      "Class::Accessor::Grouped" => 0,
      "Proc::PID::File"          => 1.24,
    );
use_test_base;
auto_include;
author_tests('xt');
WriteAll;
