package Test2::Plugin::AlienEnv;

use strict;
use warnings;

sub import
{
  delete $ENV{ACTIVESTATE_PPM_BUILD};
  delete $ENV{ALIEN_INSTALL_TYPE};
  delete $ENV{ALIEN_FORCE};
}

1;
