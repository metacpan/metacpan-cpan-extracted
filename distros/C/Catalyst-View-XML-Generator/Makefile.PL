use inc::Module::Install;

name     'Catalyst-View-XML-Generator';
all_from 'lib/Catalyst/View/XML/Generator.pm';
author   'Michael Nachbaurt <mike@nachbaur.com>';
license  'perl';

requires 'Catalyst::View';
requires 'XML::SAX::Writer';
requires 'XML::Generator::PerlData';
requires 'namespace::clean';

test_requires 'Test::More';

auto_install;

WriteAll;                                                             
