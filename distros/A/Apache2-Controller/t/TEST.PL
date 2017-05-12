
use strict;
use warnings FATAL => 'all';

use FindBin;
use YAML::Syck;

use blib;
use lib "$FindBin::Bin/lib";

use Apache2::Controller::Test::TestRun ();
  
Apache2::Controller::Test::TestRun->new->run(@ARGV);

