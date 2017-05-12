use 5.006;
use strict;
use warnings FATAL => 'all';
use inc::Module::Install;

name     'DBQuery';
all_from 'lib/DBQuery.pm';
author   q{Cnangel <cnangel@gmail.com>};
license  'bsd';

perl_version 5.006;

tests_recursive('t');

resources (
   homepage   => 'http://my.huhoo.net/study',
   #IRC        => 'irc://irc.perl.org/#DBQuery',
   license    => 'http://opensource.org/licenses/BSD-3-Clause',
   #repository => 'git://github.com/Cnangel/DBQuery.git',
   bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=DBQuery',
);

configure_requires (
   'Module::Install' => 0,
);

build_requires (
   'Test::More' => 0,
   'Test::Base' => 0.10,
);

requires (
   'DBI'              => 1.4,
);

install_as_cpan;
auto_install;
WriteAll;
