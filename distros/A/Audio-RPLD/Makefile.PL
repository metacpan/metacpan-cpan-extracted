#Makefile.PL
use strict;
use warnings;
use inc::Module::Install;

license 'gpl';

name 'Audio-RPLD';
all_from 'lib/Audio/RPLD.pm';

WriteAll;
