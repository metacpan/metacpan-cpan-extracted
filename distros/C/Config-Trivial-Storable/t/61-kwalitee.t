#   $Id: 61-kwalitee.t 49 2014-05-02 11:30:14Z adam $

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
