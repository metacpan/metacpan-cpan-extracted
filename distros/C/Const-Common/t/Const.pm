package t::Const;
use strict;
use warnings;

use Const::Common (
    FIRST  => 1,
    SECOND => 2,
    THIRD  => 3,

    MONTH => {
        JAN => 1,
        FEB => 2,
    },
);

1;
