use strict;
use warnings;
use inc::Module::Install;

name 'Audio-Moosic';
all_from 'lib/Audio/Moosic.pm';

requires 'RPC::XML';

WriteAll;
