# $Id$

use inc::Module::Install;

name('Catalyst-Plugin-AtomServer');
abstract('Atom Server implementation for Catalyst applications');
author('Six Apart <cpan@sixapart.com>');
version_from('lib/Catalyst/Plugin/AtomServer.pm');
license('perl');
no_index(directory => 't');
sign(0);

include('ExtUtils::AutoInstall');

requires('Catalyst');
requires('Catalyst::Plugin::Authentication');
requires('XML::Atom');
requires('MIME::Base64');
requires('Digest::SHA1');

auto_include();
auto_install();

&WriteAll;
