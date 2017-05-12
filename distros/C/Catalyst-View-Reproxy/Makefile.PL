use lib qw(t/lib);
use inc::Module::Install;
use MY;

@MY::INCLUDE_ENV = qw/TEST_HTTPD_PORT/;

name('Catalyst-View-Reproxy');
author('Toru Yamaguchi');
abstract('View class for lighty X-SendFile and perlbal X-REPROXY-FILE, X-REPROXY-URL');
version_from('lib/Catalyst/View/Reproxy.pm');
license('perl');

requires('Catalyst');
requires('Catalyst::View');
requires('Catalyst::Plugin::ConfigLoader');
requires('Fcntl');
requires('File::MimeInfo');
requires('File::MMagic');
requires('HTTP::Request');
requires('HTTP::Response');
requires('LWP::Simple');
requires('LWP::UserAgent');
requires('NEXT');

use_test_base;

build_requires('Test::Pod');
build_requires('Test::Pod::Coverage');
build_requires('Test::WWW::Mechanize::Catalyst');
build_requires('Catalyst::Plugin::ConfigLoader');
build_requires('Class::Accessor::Fast');
build_requires('FindBin');
build_requires('HTTP::Server::Simple::CGI');
build_requires('HTTP::Server::Simple::Static');

auto_include;
auto_install;

unless (exists $ENV{TEST_HTTPD_PORT}) {
		$ENV{TEST_HTTPD_PORT} = 3500;
}

WriteAll;
