use inc::Module::Install;

name     'AnyEvent-RPC';
author   'Mons Anderson <mons@cpan.org>';
all_from 'lib/AnyEvent/RPC.pm';
license  'perl';

build_requires 'Test::More';
build_requires 'Test::NoWarnings';
build_requires 'lib::abs', '0.90';

requires 'common::sense', '2';
requires 'parent';
requires 'AnyEvent', 5;
requires 'AnyEvent::HTTP','1.43';
requires 'URI';
requires 'HTTP::Response';
requires 'HTTP::Headers';
#recommends 'XML::Fast', '0.01';
requires 'XML::Hash::LX', '0.05';
recommends 'YAML::Syck';

auto_provides;
auto_install;

WriteAll;

