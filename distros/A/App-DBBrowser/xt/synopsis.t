use 5.010000;
use strict;
use warnings;

$SIG{__WARN__} = sub { die @_ };

use Test::Synopsis;

all_synopsis_ok();
