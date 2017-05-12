use strict;
use warnings;
use inc::Module::Install;

name 'Acme-Hyde';
all_from 'lib/Acme/Hyde.pm';

requires 'Exporter' => 0;

use_test_base;
auto_install;
WriteAll;
