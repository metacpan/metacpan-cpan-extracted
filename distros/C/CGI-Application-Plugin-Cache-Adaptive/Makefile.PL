use inc::Module::Install;

name('CGI-Application-Plugin-Cache-Adaptive');
author('Toru Yamaguchi <zigorou@cpan.org>');
version_from('lib/CGI/Application/Plugin/Cache/Adaptive.pm');
abstract('later');
license('perl');

requires('Attribute::Handlers');
requires('Cache::Adaptive');
requires('Carp');
requires('CGI::Application');
requires('Class::Inspector');
requires('Exporter');

build_requires('CGI::Application::Plugin::AutoRunmode');
build_requires('CGI::Application::Plugin::Session');
build_requires('CGI::Session');
build_requires('Test::WWW::Mechanize::CGI');

use_test_base;

auto_include;
auto_install;

WriteAll;
