use inc::Module::Install;

name     'Catalyst-View-XML-Simple';
all_from 'lib/Catalyst/View/XML/Simple.pm';
author   q{Lindolfo Rodrigues de Oliveira Neto <lorn at cpan.org>};
license  'perl';

build_requires 'Test::More';
build_requires 'XML::Simple';
build_requires 'Moose';
build_requires 'Catalyst';

auto_install;

WriteAll;

