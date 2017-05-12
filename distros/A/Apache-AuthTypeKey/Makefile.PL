# $Id: Makefile.PL 1888 2005-11-10 20:38:14Z btrott $

use inc::Module::Install;

name('Apache-AuthTypeKey');
abstract('Apache authorization handler using TypeKey');
author('Six Apart <cpan@sixapart.com>');
version_from('lib/Apache/AuthTypeKey.pm');
license('perl');
no_index(directory => 't');
sign(1);

include('ExtUtils::AutoInstall');

requires('Authen::TypeKey' => 0.02);
requires('Apache::AuthCookie' => 3.08);

auto_include();
auto_install();

&WriteAll;
