use inc::Module::Install;

my $MI  = $Module::Install::MAIN;
#auto_version    'lib/AnyEvent/Connection.pm', -d('inc/.author');
perl_version   '5.008008';
name           'AnyEvent-Connection';
all_from       'lib/AnyEvent/Connection.pm';
author         'Mons Anderson <mons@cpan.org>';
license        'perl';

build_requires 'Test::More';
build_requires 'Test::NoWarnings';
build_requires 'Test::TCP', '0.14';
build_requires 'lib::abs',  '0.90';

requires 'common::sense',    2;
requires 'AnyEvent',         5;
requires 'Object::Event',   '1.21';

auto_provides;

auto_install;

WriteAll;

print STDERR "Generated makefile for ".$MI->load('name')->name."-".$MI->load('version')->version."\n";
