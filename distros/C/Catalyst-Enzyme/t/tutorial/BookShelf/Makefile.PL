use inc::Module::Install;

name('BookShelf');
abstract('Catalyst Application');
author('Catalyst developer');
version_from('lib\BookShelf.pm');
license('perl');

requires( Catalyst => '5.57' );

install_script( glob('script/*.pl') );

catalyst_files();

&WriteAll;
