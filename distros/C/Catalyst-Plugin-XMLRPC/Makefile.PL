use inc::Module::Install 0.87;

name 'Catalyst-Plugin-XMLRPC';
all_from 'lib/Catalyst/Plugin/XMLRPC.pm';

requires Catalyst => '5.66';
requires 'RPC::XML' => '0.69';

auto_install;
resources repository => 'http://dev.catalyst.perl.org/repos/Catalyst/trunk/historical/Catalyst-Plugin-XMLRPC/';

WriteAll;
