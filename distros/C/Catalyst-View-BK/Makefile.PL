use inc::Module::Install;

name    'Catalyst-View-BK';

perl_version        '5.006';
all_from 'lib/Catalyst/View/BK.pm';

version     '0.2';
requires    'Catalyst'              => '5.7';
requires    'Catalyst::View'        => 0;
requires    'Bricklayer::Templater' => '0.9.4';
requires    'Carp'                  => 0;
requires    'NEXT'                  => 0;

build_requires      'Test::More'            => '0.7';
build_requires      'Test::MockObject'      => '1.08';

auto_install;
WriteAll;
