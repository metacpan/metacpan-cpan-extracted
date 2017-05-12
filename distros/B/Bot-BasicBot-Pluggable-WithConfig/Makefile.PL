use inc::Module::Install;
name 'Bot-BasicBot-Pluggable-WithConfig';
all_from 'lib/Bot/BasicBot/Pluggable/WithConfig.pm';

requires 'Bot::BasicBot::Pluggable';
requires 'YAML';

build_requires 'Test::More';
use_test_base;
auto_include;

install_script 'bin/bbpbot-config.pl';

WriteAll;
