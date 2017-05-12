use inc::Module::Install;

name('Catalyst-View-MicroMason');
all_from('lib/Catalyst/View/MicroMason.pm');

requires 'Catalyst::View::Templated';
requires 'Text::MicroMason';

build_requires 'Catalyst::Runtime' => 5.7;
build_requires 'Test::More';

WriteAll();
