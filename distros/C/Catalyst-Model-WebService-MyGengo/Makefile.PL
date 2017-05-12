use inc::Module::Install;

name 'Catalyst-Model-WebService-MyGengo';
all_from 'lib/Catalyst/Model/WebService/MyGengo.pm';
readme_markdown_from 'lib/Catalyst/Model/WebService/MyGengo.pm';
readme_from;

requires 'namespace::autoclean';
requires 'WebService::MyGengo' => '0.010';
requires 'Catalyst::Model::Adaptor' => '0.10';

build_requires 'Test::More';
build_requires 'Getopt::Long';

author_tests('t/author');

auto_install;
manifest_skip;
WriteAll;
