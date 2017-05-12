use inc::Module::Install;

name     'App-SocialSKK';
author   'Kentaro Kuribayashi, <kentarok@cpan.org>';
license  'MIT';
all_from 'lib/App/SocialSKK.pm';

requires POE => '1.003';
requires 'URI';
requires 'Jcode';
requires 'XML::RSS';
requires 'YAML::Syck';
requires 'Pod::Usage';
requires 'File::HomeDir';
requires 'UNIVERSAL::require';
requires 'LWP::UserAgent::POE';
requires 'Encode::JavaScript::UCS';
requires 'Class::Accessor::Lvalue::Fast';

build_requires 'Test::More';
build_requires 'Test::Class';
build_requires 'Module::Collect';
build_requires 'Filter::Util::Call';
build_requires 'Net::Ping::External';
use_test_base;
author_tests   'xt';
install_script 'bin/socialskk.pl';
auto_include_deps;
WriteAll;
