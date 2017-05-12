use 5.006;
use strict;
use warnings FATAL => 'all';
use inc::Module::Install;

name     'Catalyst-Plugin-JavaScript-Console';
all_from 'lib/Catalyst/Plugin/JavaScript/Console.pm';
author   q{Akzhan Abdulin <akzhan.abdulin@gmail.com>};
license  'artistic2';

perl_version 5.006;

tests_recursive('t');

resources (
   homepage   => 'https://github.com/regru/Catalyst-Plugin-JavaScript-Console',
   #IRC        => 'irc://irc.perl.org/#Catalyst-Plugin-JavaScript-Console',
   license    => 'http://www.perlfoundation.org/artistic_license_2_0',
   repository => 'git@github.com:regru/Catalyst-Plugin-JavaScript-Console.git',
   bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Catalyst-Plugin-JavaScript-Console',
);

configure_requires (
   'Module::Install' => 0,
);

build_requires (
   'Test::More' => 0,
);

requires (
   'Catalyst::Runtime' => 5,
   'MRO::Compat' => 0,
   'Moose' => 0,
   'JavaScript::Console' => 0,
);

install_as_cpan;
auto_install;
WriteAll;
