# $Id$

use inc::Module::Install;

name('Catalyst-Plugin-MortalForward');
abstract('Make $c->forward() throw exceptions');
author('Six Apart <cpan@sixapart.com>');
version_from('lib/Catalyst/Plugin/MortalForward.pm');
license('perl');
no_index(directory => 't');
sign(0);

include('ExtUtils::AutoInstall');

requires('Catalyst');

auto_include();
auto_install();
 
&WriteAll;
