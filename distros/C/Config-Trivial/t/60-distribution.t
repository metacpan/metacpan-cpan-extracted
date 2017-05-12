#   $Id: 60-distribution.t 51 2014-05-21 19:14:11Z adam $

use Test::More;
BEGIN {
    eval { require Test::Distribution; };
    if($@) {
        plan skip_all => 'Test::Distribution not installed';
    }
    else {
        import Test::Distribution;
    }
};
