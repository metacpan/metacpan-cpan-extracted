#!/usr/bin/perl

use strict;
use inc::Module::Install;

name        'Acme-emcA';
all_from    'lib/Acme/emcA.pm';
auto_provides;

sign; WriteAll;
