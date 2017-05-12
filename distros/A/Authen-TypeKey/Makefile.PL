# $Id: Makefile.PL 1821 2005-05-15 20:15:02Z btrott $

use inc::Module::Install;

name('Authen-TypeKey');
abstract('TypeKey Authentication');
author('Six Apart <cpan@sixapart.com>');
version_from('lib/Authen/TypeKey.pm');
license('perl');
no_index(directory => 't');
sign(1);

include('ExtUtils::AutoInstall');

requires('Class::ErrorHandler');
requires('Math::BigInt');
requires('MIME::Base64');
requires('Digest::SHA1');
requires('LWP');

auto_include();
auto_install();

&WriteAll;
