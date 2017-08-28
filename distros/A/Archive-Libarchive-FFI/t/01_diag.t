use strict;
use warnings;
use lib 'inc/Linux-Distribution/lib';
use Config;
use Test::More tests => 1;

pass 'okay';

diag '';
diag '';
diag '';
diag 'os                   = ', $Config{osname};
diag 'version              = ', $Config{osvers};
diag '';
diag '';
diag '';
