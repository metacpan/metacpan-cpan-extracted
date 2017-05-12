use inc::Module::Install;

name('Catalyst-Plugin-BuildURI');
author('Toru Yamaguchi <zigorou@cpan.org>');
abstract('Build URI by action name, namespace, and args');
version_from('lib/Catalyst/Plugin/BuildURI.pm');
license('perl');

requires('Catalyst');
requires('Catalyst::Exception');
requires('URI');
requires('URI::Escape');

build_requires('Test::More');

auto_include;
auto_install;
WriteAll;
