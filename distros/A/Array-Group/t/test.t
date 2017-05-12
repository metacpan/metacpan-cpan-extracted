# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 9;
#BEGIN { plan  };
use Array::Group qw( :all );
ok(1); # If we made it this far, we're ok.

diag("Array::Group::VERSION $Array::Group::VERSION");

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

our (@orig, $size, @new, $new);

@orig = ( 1 .. 16 );
$size = 8;
@new = ngroup( $size, \@orig );
ok( scalar @new == 2 );

# check class methods work
@new = Array::Group->ngroup( $size, \@orig );
ok( scalar @new == 2 );

# check calling with an array rather than an arrayref works
#@new = ngroup( $size, @orig );
#ok( scalar @new == 2 );

$size = 4;
$new = ngroup( $size, \@orig );
ok( scalar @$new == 4 );

$size = 5;
@new = dissect( $size, \@orig );
ok( scalar @new == 5 );

@orig = ( 1 .. 5 );
$size = 2;
@new = ngroup( $size, \@orig );
ok( $new[0][1] == 2 && $new[2][0] == 5 );

@new = dissect( $size, \@orig );
ok( $new[1][0] == 2 && $new[0][1] == 3 );

$size = 3;
@new = dissect( $size, \@orig );
is( $new[0][1], 4 ); is( $new[2][0], 3 );
