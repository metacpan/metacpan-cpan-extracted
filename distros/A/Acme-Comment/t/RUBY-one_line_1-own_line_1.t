BEGIN { unshift @INC, '/home/chris/dev/perlmods/git/kane/Acme-Comment/lib'; }

use strict;
use Test::More q[no_plan];

use Acme::Comment 1.01 type => "RUBY", one_line => 1, own_line => 1;


SKIP: {
    ### Test 4 ###
    my $four = 4;

    =begin $four= 5; =end

    ### Check Test 1 ###
    is($four, 4, "RUBY => own_line: 1, one_line: 1: Standard Multiline");



    ### Test 5 ###
    my $five = 5;

    =begin $five = 7; =begin $five = 8; =end $five = 9; =end

    ### Check Test 5 ###
    is($five, 5, "RUBY => own_line: 1, one_line: 1: Nested Multiline");


    ### Test 6 ###
    eval {
        =begin this should break =end
        1;
    };

    ### Check 6 ###
    ok(!$@, "RUBY => own_line: 1, one_line: 1: Broken Syntax Ignored Multiline");
}
### Test 7 ###
my $seven = 7;

=begin
    $seven = 8;
=end

### Check Test 7 ###
is($seven, 7, "RUBY => own_line: 1, one_line: 1: Standard Multiline");



### Test 8 ###
my $eight = 8;

=begin
    $eight = 9;
    =begin
        $eight = 10;
    =end
    $eight = 11;
=end

### Check Test 8 ###
is($eight, 8, "RUBY => own_line: 1, one_line: 1: Nested Multiline");

### Test 9 ###
eval {
    =begin
        this should break
    =end
    1;
};

### Check 9 ###
ok(!$@, "RUBY => own_line: 1, one_line: 1: Broken Syntax Ignored Multiline");


my $ten = 10;
# $ten = 11;

is($ten, 10, "RUBY => own_line: 1, one_line: 1: Standard Single Line");

