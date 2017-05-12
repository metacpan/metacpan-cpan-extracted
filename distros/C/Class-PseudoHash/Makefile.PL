#!/usr/bin/perl

use 5.005;
use strict;
use inc::Module::Install;

name        'Class-PseudoHash';
all_from    'lib/Class/PseudoHash.pm';

include_deps 'Test::More';
auto_provides;

sign; WriteAll;
