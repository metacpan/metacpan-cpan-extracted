BEGIN { unshift @INC, '/home/chris/dev/perlmods/git/kane/Acme-Comment/lib'; }

use strict;
use Test::More q[no_plan];

use Acme::Comment 1.01 type => "HUGO", one_line => 1, own_line => 1;


SKIP: {
    ### Test 4 ###
    my $four = 4;

    !\ $four= 5; \!

    ### Check Test 1 ###
    is($four, 4, "HUGO => own_line: 1, one_line: 1: Standard Multiline");



    ### Test 5 ###
    my $five = 5;

    !\ $five = 7; !\ $five = 8; \! $five = 9; \!

    ### Check Test 5 ###
    is($five, 5, "HUGO => own_line: 1, one_line: 1: Nested Multiline");


    ### Test 6 ###
    eval {
        !\ this should break \!
        1;
    };

    ### Check 6 ###
    ok(!$@, "HUGO => own_line: 1, one_line: 1: Broken Syntax Ignored Multiline");
}
### Test 7 ###
my $seven = 7;

!\
    $seven = 8;
\!

### Check Test 7 ###
is($seven, 7, "HUGO => own_line: 1, one_line: 1: Standard Multiline");



### Test 8 ###
my $eight = 8;

!\
    $eight = 9;
    !\
        $eight = 10;
    \!
    $eight = 11;
\!

### Check Test 8 ###
is($eight, 8, "HUGO => own_line: 1, one_line: 1: Nested Multiline");

### Test 9 ###
eval {
    !\
        this should break
    \!
    1;
};

### Check 9 ###
ok(!$@, "HUGO => own_line: 1, one_line: 1: Broken Syntax Ignored Multiline");

