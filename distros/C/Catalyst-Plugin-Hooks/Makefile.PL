use inc::Module::Install;


warn qq/
===========================================================================
Use Catalyst::Plugin::Observe. All functionality provided in C:P:Hooks will
very shortly be available in C:P:Observe. C:P:Hooks is probably not going to
work in the next Catalyst release, so rewrite your code to use C:P:Observe.
===========================================================================
/;

name('Catalyst-Plugin-Hooks');
abstract('Hooks to Catalyst');
author('Berik Visschers');
version_from('lib/Catalyst/Plugin/Hooks.pm');
license('perl');

include('ExtUtils::AutoInstall');

requires( Catalyst => '5.7' );

catalyst_files();

#install_script( glob('script/*.pl') );
auto_install();
&WriteAll;

warn qq/
===========================================================================
Use Catalyst::Plugin::Observe. All functionality provided in C:P:Hooks will
very shortly be available in C:P:Observe. C:P:Hooks is probably not going to
work in the next Catalyst release, so rewrite your code to use C:P:Observe.
===========================================================================
/;

