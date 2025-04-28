use 5.016;
use strict;
use warnings;

$SIG{__WARN__} = sub { die @_ };

use Test::Synopsis;

all_synopsis_ok();
