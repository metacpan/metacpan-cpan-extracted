use inc::Module::Install;
use strict;
use warnings;

name 'Catalyst-Component-ACCEPT_CONTEXT';
all_from 'lib/Catalyst/Component/ACCEPT_CONTEXT.pm';

requires 'Catalyst';
requires 'Scalar::Util';
requires 'MRO::Compat';
build_requires 'Devel::Cycle';

resources repository => 'git://git.shadowcat.co.uk/catagits/Catalyst-Component-ACCEPT_CONTEXT';

auto_install;
WriteAll;

