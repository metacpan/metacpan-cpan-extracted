use strict;
use warnings;
use inc::Module::Install 0.91;

name 'Catalyst-View-Petal';
all_from 'lib/Catalyst/View/Petal.pm';

requires 'Catalyst::Runtime' => '5.7006';
requires 'Petal';

auto_install;
resources repository => 'http://dev.catalyst.perl.org/repos/Catalyst/Catalyst-View-Petal/';

WriteAll;
