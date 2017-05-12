use inc::Module::Install;
name 'App-CLI-Plugin-Net-SMTP';
author 'Akira Horimoto';
all_from 'lib/App/CLI/Plugin/Net/SMTP.pm';

build_requires 'Test::More';
requires(
      "App::CLI::Extension"      => 1.2,
      "Class::Accessor::Grouped" => 0,
      "Net::SMTP"                => 0,
    );
use_test_base;
auto_include;
author_tests('xt');
WriteAll;
