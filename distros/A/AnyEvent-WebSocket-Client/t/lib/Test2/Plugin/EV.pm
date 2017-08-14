package Test2::Plugin::EV;

use strict;
use warnings;

eval q{
  require EV;
  EV->import;
};

1;
