use strict;
use warnings;

use lib 'lib';

package TestApp;
use App::Cmd::Setup -app => {
  plugins => [ qw(Prompt) ],
};

1;
