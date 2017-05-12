use inc::Module::Install;

name    'Bricklayer-Templater';

perl_version        '5.006';
all_from 'lib/Bricklayer/Templater.pm';

requires            'Carp'              => 0;

build_requires      'Test::More'        => '0.7';
build_requires      'Test::MockObject'  => '1.08';

auto_install;
WriteAll;
