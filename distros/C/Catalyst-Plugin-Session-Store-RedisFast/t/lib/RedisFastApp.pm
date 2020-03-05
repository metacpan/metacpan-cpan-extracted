package RedisFastApp;

use strict;
use warnings;
use utf8;

use Catalyst qw /
    Session::Store::RedisFast
/;

use namespace::autoclean;

__PACKAGE__->setup();

1;
