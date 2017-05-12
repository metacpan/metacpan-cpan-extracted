use inc::Module::Install;

name('Catalyst-Plugin-HTML-Widget');
abstract('HTML Widget Catalyst Plugin');
author('Sebastian Riedel');
version_from('lib/Catalyst/Plugin/HTML/Widget.pm');
license('perl');

include('ExtUtils::AutoInstall');

requires( 'perl'     => '5.8.1' );
requires( 'Catalyst' => '5.5' );
requires('HTML::Widget');

auto_install();
&WriteAll;
