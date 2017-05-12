#   $Id: 60-distribution.t 49 2014-05-02 11:30:14Z adam $

use Test::More;

BEGIN {
    eval { require Test::Distribution; };
    if( $@ ) {
        plan skip_all => 'Test::Distribution not installed, skipping test.';
    }
    else {
        import Test::Distribution;
    }
};
