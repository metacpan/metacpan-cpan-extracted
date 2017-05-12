use inc::Module::Install;

name 'CatalystX-ListFramework';
all_from 'lib/CatalystX/ListFramework.pm';

build_requires 'Catalyst::Runtime';
build_requires 'Test::WWW::Mechanize::Catalyst';
build_requires 'Test::More';
build_requires 'HTML::Widget';
build_requires 'DBD::SQLite2';
build_requires 'Catalyst::View::JSON';
build_requires 'ok';

WriteAll();
