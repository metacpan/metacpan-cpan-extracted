use 5.010;
use strict;
use warnings FATAL => 'all';
use inc::Module::Install;

name     'App-minecraft';
all_from 'lib/App/minecraft.pm';
author   q{Brad Haywood <brad@perlpowered.com>};
license  'artistic2';

perl_version 5.010;

tests_recursive('t');

resources (
   #homepage   => 'http://yourwebsitehere.com',
   #IRC        => 'irc://irc.perl.org/#App-minecraft',
   license    => 'http://www.perlfoundation.org/artistic_license_2_0',
   #repository => 'git://github.com/Brad Haywood/App-minecraft.git',
   bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-minecraft',
);

configure_requires (
   'Module::Install' => 0,
);

build_requires (
   'Test::More' => 0,
);

requires (
   'Archive::Zip'           => '1.30',
   'Cwd'                    => 0,
   'File::Path'             => 0,
   'File::Copy::Recursive'  => '0.38',
);

install_script 'script/minecraft.pl';
install_as_cpan;
auto_install;
WriteAll;
