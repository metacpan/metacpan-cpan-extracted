use inc::Module::Install;

name     'Catalyst-View-XML-Hash-LX';
all_from 'lib/Catalyst/View/XML/Hash/LX.pm';
author   'Andrii Kostenko <andrey@kostenko.name>';
license  'perl';

requires 'Catalyst::View';
requires 'XML::Hash::LX' => '0.0602';
requires 'namespace::clean';

test_requires 'Test::More';

auto_install;

WriteAll;                                                             
