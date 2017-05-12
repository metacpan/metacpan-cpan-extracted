use inc::Module::Install;

name('Data-Feed');

all_from('lib/Data/Feed.pm');

requires 'DateTime::Format::Mail';
requires 'DateTime::Format::W3CDTF';
requires 'DateTime::Format::Natural';
requires 'DateTime::Format::Flexible';
requires 'DateTime::Format::ISO8601';
requires 'LWP::UserAgent';
requires 'XML::Atom';
requires 'XML::RSS::LibXML' => '0.3101';
requires_any_moose;

test_requires('Test::More' => '0.84');
test_requires('Test::UseAllModules');

tests('t/*.t t/*/*.t');
auto_set_repository;
author_tests 'xt';

WriteAll;
