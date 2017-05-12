BEGIN { unshift @INC, '/home/chris/dev/perlmods/git/kane/Acme-Comment/lib'; }

use strict;
use Test::More q[no_plan];

use Acme::Comment 1.01 type => "CHILL", one_line => 0, own_line => 0;


SKIP: {
    ### Test 1 ###
    my $one = 1;

    /* $one = 2;
    */

    ### Check Test 1 ###
    is($one, 1, "CHILL => own_line: 0, one_line: 0: Standard Multiline");



    ### Test 2 ###
    my $two = 2;

    /* $two = 3; /* $two = 4;
    */ $two = 5; */

    ### Check Test 2 ###
    is($two, 2, "CHILL => own_line: 0, one_line: 0: Nested Multiline");



    ### Test 3 ###
    eval {
        /* this should break
        */
        1;
    };

    ### Check 3 ###
    ok(!$@, "CHILL => own_line: 0, one_line: 0: Broken Syntax Ignored Multiline");
}
### Test 7 ###
my $seven = 7;

/*
    $seven = 8;
*/

### Check Test 7 ###
is($seven, 7, "CHILL => own_line: 0, one_line: 0: Standard Multiline");



### Test 8 ###
my $eight = 8;

/*
    $eight = 9;
    /*
        $eight = 10;
    */
    $eight = 11;
*/

### Check Test 8 ###
is($eight, 8, "CHILL => own_line: 0, one_line: 0: Nested Multiline");

### Test 9 ###
eval {
    /*
        this should break
    */
    1;
};

### Check 9 ###
ok(!$@, "CHILL => own_line: 0, one_line: 0: Broken Syntax Ignored Multiline");

