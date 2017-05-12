use strict;
use Test::More;

use_ok("App::pscan");

use_ok("App::pscan::Command::Tcp");
use_ok("App::pscan::Command::Udp");
use_ok("App::pscan::Command::Discover");


done_testing;
