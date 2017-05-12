use 5.006;
use strict;
use warnings FATAL => 'all';
use inc::Module::Install;

name     'Data-Record-Serialize';
all_from 'lib/Data/Record/Serialize.pm';
author   q{Diab Jerius <djerius@cpan.org>};
license  'gpl3';

perl_version 5.010001;

tests_recursive('t');

resources (
   license    => 'http://www.gnu.org/licenses/gpl-3.0.html',
   repository => 'https://bitbucket.org/djerius/data-record-serialize',
   bugtracker => 'https://rt.cpan.org/Dist/Display.html?Name=Data-Record-Serialize',
);

install_as_cpan;

cpanfile;
auto_install;
WriteAll;
