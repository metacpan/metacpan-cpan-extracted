use inc::Module::Install 0.87;

name 'Catalyst-View-REST-XML';
all_from 'lib/Catalyst/View/REST/XML.pm';

requires 'Catalyst::Runtime';
requires 'XML::Simple';

requires 'Test::More';

auto_install;
resources repository => 'http://dev.catalyst.perl.org/repos/Catalyst/trunk/historical/Catalyst-View-REST-XML/';

WriteAll;
