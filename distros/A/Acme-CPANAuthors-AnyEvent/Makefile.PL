use inc::Module::Install;

name     'Acme-CPANAuthors-AnyEvent';
all_from 'lib/Acme/CPANAuthors/AnyEvent.pm';
author   'Mons Anderson <mons@cpan.org>';
license  'perl';

build_requires 'Test::More';
build_requires 'Test::NoWarnings';
build_requires 'lib::abs', '0.90';

requires 'Acme::CPANAuthors::Register';
requires 'Acme::CPANAuthors';

provides 'Acme::CPANAuthors::AnyEvent' => {
	version => '0.05',
	file    => 'lib/Acme/CPANAuthors/AnyEvent.pm',
};

auto_install;

WriteAll;

