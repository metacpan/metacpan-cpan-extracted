BEGIN { unshift @INC, '/home/chris/dev/perlmods/git/kane/Acme-Comment/lib'; }

use strict;
use Test::More q[no_plan];

use Acme::Comment 1.01 type => "VAR'AQ", one_line => 1, own_line => 0;


SKIP: {
    ### Test 1 ###
    my $one = 1;

    (* $one = 2;
    *)

    ### Check Test 1 ###
    is($one, 1, "VAR'AQ => own_line: 0, one_line: 1: Standard Multiline");



    ### Test 2 ###
    my $two = 2;

    (* $two = 3; (* $two = 4;
    *) $two = 5; *)

    ### Check Test 2 ###
    is($two, 2, "VAR'AQ => own_line: 0, one_line: 1: Nested Multiline");



    ### Test 3 ###
    eval {
        (* this should break
        *)
        1;
    };

    ### Check 3 ###
    ok(!$@, "VAR'AQ => own_line: 0, one_line: 1: Broken Syntax Ignored Multiline");
}
SKIP: {
    ### Test 4 ###
    my $four = 4;

    (* $four= 5; *)

    ### Check Test 1 ###
    is($four, 4, "VAR'AQ => own_line: 0, one_line: 1: Standard Multiline");



    ### Test 5 ###
    my $five = 5;

    (* $five = 7; (* $five = 8; *) $five = 9; *)

    ### Check Test 5 ###
    is($five, 5, "VAR'AQ => own_line: 0, one_line: 1: Nested Multiline");


    ### Test 6 ###
    eval {
        (* this should break *)
        1;
    };

    ### Check 6 ###
    ok(!$@, "VAR'AQ => own_line: 0, one_line: 1: Broken Syntax Ignored Multiline");
}
### Test 7 ###
my $seven = 7;

(*
    $seven = 8;
*)

### Check Test 7 ###
is($seven, 7, "VAR'AQ => own_line: 0, one_line: 1: Standard Multiline");



### Test 8 ###
my $eight = 8;

(*
    $eight = 9;
    (*
        $eight = 10;
    *)
    $eight = 11;
*)

### Check Test 8 ###
is($eight, 8, "VAR'AQ => own_line: 0, one_line: 1: Nested Multiline");

### Test 9 ###
eval {
    (*
        this should break
    *)
    1;
};

### Check 9 ###
ok(!$@, "VAR'AQ => own_line: 0, one_line: 1: Broken Syntax Ignored Multiline");

