use inc::Module::Install 0.87;

name 'Catalyst-Plugin-Session-Store-DBI';
all_from 'lib/Catalyst/Plugin/Session/Store/DBI.pm';

requires 'Catalyst::Runtime'         => '5.49';
requires 'Catalyst::Plugin::Session' => '0.27';
requires 'DBI';
requires 'MIME::Base64';
requires 'Storable';
requires 'Test::More';
requires 'MRO::Compat';

auto_install;
resources repository => 'http://dev.catalyst.perl.org/repos/Catalyst/Catalyst-Plugin-Session-Store-DBI/';

WriteAll;
