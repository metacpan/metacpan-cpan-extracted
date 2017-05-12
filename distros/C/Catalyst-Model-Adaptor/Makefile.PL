use inc::Module::Install 0.91;
use Module::Install::ReadmeFromPod;
use Module::Install::AuthorTests;

name 'Catalyst-Model-Adaptor';
all_from 'lib/Catalyst/Model/Adaptor.pm';
readme_from;

requires 'MRO::Compat';
requires 'Catalyst::Runtime';

build_requires 'Test::More';
build_requires 'ok';

author_tests('t/author');

repository 'git://github.com/bobtfish/catalyst-model-adaptor.git';

WriteAll();
