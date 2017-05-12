use inc::Module::Install;

name     'CHI-Driver-Redis';
version_from 'lib/CHI/Driver/Redis.pm';
author   q{Cory G Watson <gphat@cpan.org>};
license  'perl';
repository 'https://github.com/rentrak/chi-driver-redis';

perl_version '5.006';

build_requires 'Test::Class';
build_requires 'Test::More';
build_requires 'Test::Mock::Redis';

requires 'CHI' => '0.36';
requires 'Moo';
requires 'Redis' => '1.901';
requires 'URI';

WriteAll;

