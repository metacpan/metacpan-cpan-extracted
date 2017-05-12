package t::Const2;
use strict;
use warnings;
use utf8;

use t::Const ();

use Const::Common (
    %{ t::Const->constants },
    BAR => 'BAZ',
);

1;
