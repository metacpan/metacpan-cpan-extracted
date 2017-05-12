use inc::Module::Install;

name('Catalyst-Helper-FastCGI-ExternalServer');
author('Toru Yamaguchi <zigorou@cpan.org>');
author('Naoya Sano <sano@naoya.net>');
abstract('FastCGI daemon start/stop script for using FastCgiExternalServer');
version_from('lib/Catalyst/Helper/FastCGI/ExternalServer.pm');
license('perl');

requires('Catalyst');
requires('Catalyst::Utils');

requires('Cwd');
requires('DateTime');
requires('FCGI');
requires('FCGI::ProcManager');
requires('File::Spec');
requires('Getopt::Long');

use_test_base;

auto_include;
auto_install;

WriteAll;
