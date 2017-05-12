use strict;
use warnings;
use inc::Module::Install;

name 'Config-PFiles-Path';
license 'gpl3';
auto_license( holder => 'Smithsonian Astrophysical Observatory' );
all_from 'lib/Config/PFiles/Path.pm';

resources (
   license    => 'http://www.gnu.org/licenses/gpl-3.0.html',
   repository => 'https://bitbucket.org/djerius/config-pfiles-path',
   bugtracker => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Config-PFiles-Path',
);

author_tests( 'xt' );

cpanfile;

WriteAll;
