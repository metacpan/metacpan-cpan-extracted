use strict;
use warnings;
use inc::Module::Install;

name 'App-Env';

license 'gpl3';
auto_license( holder => 'Smithsonian Astrophysical Observatory' );
all_from 'lib/App/Env.pm';

resources (
   license    => 'http://www.gnu.org/licenses/gpl-3.0.html',
   repository => 'https://bitbucket.org/djerius/app-env',
   bugtracker => 'https://rt.cpan.org/Public/Dist/Display.html?Name=App-Env',
);

install_script 'bin/appexec';

readme_from;
readme_from '', { format => 'md' };;

author_tests( 'xt' );

cpanfile;

WriteAll;
