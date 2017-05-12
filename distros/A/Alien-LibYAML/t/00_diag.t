use strict;
use warnings;
use Test::More;
use Alien::LibYAML;

ok 1;

diag '';
diag '';
diag '';

diag "type           = ", Alien::LibYAML->install_type;
diag "version        = ", Alien::LibYAML->version;
diag "cflags         = ", Alien::LibYAML->cflags;
diag "cflags_static  = ", Alien::LibYAML->cflags_static;
diag "libs           = ", Alien::LibYAML->libs;
diag "libs_static    = ", Alien::LibYAML->libs_static;

diag '';
diag '';

done_testing;
