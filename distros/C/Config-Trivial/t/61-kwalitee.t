#   $Id: 61-kwalitee.t 51 2014-05-21 19:14:11Z adam $

use strict;
use Test::More;

BEGIN {
    eval { require Test::Kwalitee; };
    if ( $@ ) {
        plan skip_all => 'Test::Kwalitee not installed';
    }
    else {
        Test::Kwalitee->import();
    }
};
