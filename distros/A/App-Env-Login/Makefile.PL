#! perl

use strict;
use warnings;
use inc::Module::Install;

name 'App-Env-Login';
license 'gpl3';
auto_license( holder => 'Smithsonian Astrophysical Observatory' );
all_from 'lib/App/Env/Login.pm';

resources (
   license    => 'http://www.gnu.org/licenses/gpl-3.0.html',
   repository => 'https://github.com/djerius/app-env-login',
   bugtracker => 'https://rt.cpan.org/Public/Dist/Display.html?Name=App-Env-Login',
);

author_tests( 'xt' );

readme_from;
readme_from '', { format => 'md' };;

cpanfile;

WriteAll;
