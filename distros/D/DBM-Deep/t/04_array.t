use strict;
use warnings FATAL => 'all';

use Test::More;
use Test::Exception;
use t::common qw( new_dbm );

use_ok( 'DBM::Deep' );

my $dbm_factory = new_dbm( type => DBM::Deep->TYPE_ARRAY );
while ( my $dbm_maker = $dbm_factory->() ) {
    my $db = $dbm_maker->();

    ##
    # basic put/get/push
    ##
    $db->[0] = "elem1";
    $db->push( "elem2" );
    $db->put(2, "elem3");
    $db->store(3, "elem4");
    $db->unshift("elem0");

    is( $db->[0], 'elem0', "Array get for shift works" );
    is( $db->[1], 'elem1', "Array get for array set works" );
    is( $db->[2], 'elem2', "Array get for push() works" );
    is( $db->[3], 'elem3', "Array get for put() works" );
    is( $db->[4], 'elem4', "Array get for store() works" );

    is( $db->get(0), 'elem0', "get() for shift() works" );
    is( $db->get(1), 'elem1', "get() for array set works" );
    is( $db->get(2), 'elem2', "get() for push() works" );
    is( $db->get(3), 'elem3', "get() for put() works" );
    is( $db->get(4), 'elem4', "get() for store() works" );

    is( $db->fetch(0), 'elem0', "fetch() for shift() works" );
    is( $db->fetch(1), 'elem1', "fetch() for array set works" );
    is( $db->fetch(2), 'elem2', "fetch() for push() works" );
    is( $db->fetch(3), 'elem3', "fetch() for put() works" );
    is( $db->fetch(4), 'elem4', "fetch() for store() works" );

    is( $db->length, 5, "... and we have five elements" );

    is( $db->[-1], $db->[4], "-1st index is 4th index" );
    is( $db->[-2], $db->[3], "-2nd index is 3rd index" );
    is( $db->[-3], $db->[2], "-3rd index is 2nd index" );
    is( $db->[-4], $db->[1], "-4th index is 1st index" );
    is( $db->[-5], $db->[0], "-5th index is 0th index" );

    # This is for Perls older than 5.8.0 because of is()'s prototype
    { my $v = $db->[-6]; is( $v, undef, "-6th index is undef" ); }

    is( $db->length, 5, "... and we have five elements after abortive -6 index lookup" );

    $db->[-1] = 'elem4.1';
    is( $db->[-1], 'elem4.1' );
    is( $db->[4], 'elem4.1' );
    is( $db->get(4), 'elem4.1' );
    is( $db->fetch(4), 'elem4.1' );

    throws_ok {
        $db->[-6] = 'whoops!';
    } qr/Modification of non-creatable array value attempted, subscript -6/, "Correct error thrown";

    my $popped = $db->pop;
    is( $db->length, 4, "... and we have four after popping" );
    is( $db->[0], 'elem0', "0th element still there after popping" );
    is( $db->[1], 'elem1', "1st element still there after popping" );
    is( $db->[2], 'elem2', "2nd element still there after popping" );
    is( $db->[3], 'elem3', "3rd element still there after popping" );
    is( $popped, 'elem4.1', "Popped value is correct" );

    my $shifted = $db->shift;
    is( $db->length, 3, "... and we have three after shifting" );
    is( $db->[0], 'elem1', "0th element still there after shifting" );
    is( $db->[1], 'elem2', "1st element still there after shifting" );
    is( $db->[2], 'elem3', "2nd element still there after shifting" );
    is( $db->[3], undef, "There is no third element now" );
    is( $shifted, 'elem0', "Shifted value is correct" );

    ##
    # delete
    ##
    my $deleted = $db->delete(0);
    is( $db->length, 3, "... and we still have three after deleting" );
    is( $db->[0], undef, "0th element now undef" );
    is( $db->[1], 'elem2', "1st element still there after deleting" );
    is( $db->[2], 'elem3', "2nd element still there after deleting" );
    is( $deleted, 'elem1', "Deleted value is correct" );

    is( $db->delete(99), undef, 'delete on an element not in the array returns undef' );
    is( $db->length, 3, "... and we still have three after a delete on an out-of-range index" );

    is( delete $db->[99], undef, 'DELETE on an element not in the array returns undef' );
    is( $db->length, 3, "... and we still have three after a DELETE on an out-of-range index" );

    is( $db->delete(-99), undef, 'delete on an element (neg) not in the array returns undef' );
    is( $db->length, 3, "... and we still have three after a DELETE on an out-of-range negative index" );

    is( delete $db->[-99], undef, 'DELETE on an element (neg) not in the array returns undef' );
    is( $db->length, 3, "... and we still have three after a DELETE on an out-of-range negative index" );

    $deleted = $db->delete(-2);
    is( $db->length, 3, "... and we still have three after deleting" );
    is( $db->[0], undef, "0th element still undef" );
    is( $db->[1], undef, "1st element now undef" );
    is( $db->[2], 'elem3', "2nd element still there after deleting" );
    is( $deleted, 'elem2', "Deleted value is correct" );

    $db->[1] = 'elem2';

    ##
    # exists
    ##
    ok( $db->exists(1), "The 1st value exists" );
    ok( !$db->exists(0), "The 0th value doesn't exist" );
    ok( !$db->exists(22), "The 22nd value doesn't exists" );
    ok( $db->exists(-1), "The -1st value does exists" );
    ok( !$db->exists(-22), "The -22nd value doesn't exists" );

    ##
    # clear
    ##
    ok( $db->clear(), "clear() returns true if the file was ever non-empty" );
    is( $db->length(), 0, "After clear(), no more elements" );

    is( $db->pop, undef, "pop on an empty array returns undef" );
    is( $db->length(), 0, "After pop() on empty array, length is still 0" );

    is( $db->shift, undef, "shift on an empty array returns undef" );
    is( $db->length(), 0, "After shift() on empty array, length is still 0" );

    is( $db->unshift( 1, 2, 3 ), 3, "unshift returns the number of elements in the array" );
    is( $db->unshift( 1, 2, 3 ), 6, "unshift returns the number of elements in the array" );
    is( $db->push( 1, 2, 3 ), 9, "push returns the number of elements in the array" );

    is( $db->length(), 9, "After unshift and push on empty array, length is now 9" );

    $db->clear;

    ##
    # push with non-true values
    ##
    $db->push( 'foo', 0, 'bar', undef, 'baz', '', 'quux' );
    is( $db->length, 7, "7-element push results in seven elements" );
    is( $db->[0], 'foo', "First element is 'foo'" );
    is( $db->[1], 0, "Second element is 0" );
    is( $db->[2], 'bar', "Third element is 'bar'" );
    is( $db->[3], undef, "Fourth element is undef" );
    is( $db->[4], 'baz', "Fifth element is 'baz'" );
    is( $db->[5], '', "Sixth element is ''" );
    is( $db->[6], 'quux', "Seventh element is 'quux'" );
    $db->clear;

    ##
    # multi-push
    ##
    $db->push( 'elem first', "elem middle", "elem last" );
    is( $db->length, 3, "3-element push results in three elements" );
    is($db->[0], "elem first", "First element is 'elem first'");
    is($db->[1], "elem middle", "Second element is 'elem middle'");
    is($db->[2], "elem last", "Third element is 'elem last'");

    ##
    # splice with length 1
    ##
    my @returned = $db->splice( 1, 1, "middle A", "middle B" );
    is( scalar(@returned), 1, "One element was removed" );
    is( $returned[0], 'elem middle', "... and it was correctly removed" );
    is($db->length(), 4);
    is($db->[0], "elem first");
    is($db->[1], "middle A");
    is($db->[2], "middle B");
    is($db->[3], "elem last");

    ##
    # splice with length of 0
    ##
    @returned = $db->splice( -1, 0, "middle C" );
    is( scalar(@returned), 0, "No elements were removed" );
    is($db->length(), 5);
    is($db->[0], "elem first");
    is($db->[1], "middle A");
    is($db->[2], "middle B");
    is($db->[3], "middle C");
    is($db->[4], "elem last");

    ##
    # splice with length of 3
    ##
    my $returned = $db->splice( 1, 3, "middle ABC" );
    is( $returned, 'middle C', "Just the last element was returned" );
    is($db->length(), 3);
    is($db->[0], "elem first");
    is($db->[1], "middle ABC");
    is($db->[2], "elem last");

    @returned = $db->splice( 1 );
    is($db->length(), 1);
    is($db->[0], "elem first");
    is($returned[0], "middle ABC");
    is($returned[1], "elem last");

    $db->push( @returned );

    @returned = $db->splice( 1, -1 );
    is($db->length(), 2);
    is($db->[0], "elem first");
    is($db->[1], "elem last");
    is($returned[0], "middle ABC");

    @returned = $db->splice;
    is( $db->length, 0 );
    is( $returned[0], "elem first" );
    is( $returned[1], "elem last" );

    $db->[0] = [ 1 .. 3 ];
    $db->[1] = { a => 'foo' };
    is( $db->[0]->length, 3, "Reuse of same space with array successful" );
    is( $db->[1]->fetch('a'), 'foo', "Reuse of same space with hash successful" );

    # Test autovivification
    $db->[9999]{bar} = 1;
    ok( $db->[9999] );
    cmp_ok( $db->[9999]{bar}, '==', 1 );

    # Test failures
    throws_ok {
        $db->fetch( 'foo' );
    } qr/Cannot use 'foo' as an array index/, "FETCH fails on an illegal key";

    throws_ok {
        $db->fetch();
    } qr/Cannot use an undefined array index/, "FETCH fails on an undefined key";

    throws_ok {
        $db->store( 'foo', 'bar' );
    } qr/Cannot use 'foo' as an array index/, "STORE fails on an illegal key";

    throws_ok {
        $db->store();
    } qr/Cannot use an undefined array index/, "STORE fails on an undefined key";

    throws_ok {
        $db->delete( 'foo' );
    } qr/Cannot use 'foo' as an array index/, "DELETE fails on an illegal key";

    throws_ok {
        $db->delete();
    } qr/Cannot use an undefined array index/, "DELETE fails on an undefined key";

    throws_ok {
        $db->exists( 'foo' );
    } qr/Cannot use 'foo' as an array index/, "EXISTS fails on an illegal key";

    throws_ok {
        $db->exists();
    } qr/Cannot use an undefined array index/, "EXISTS fails on an undefined key";
}

# Bug reported by Mike Schilli
# Also, RT #29583 reported by HANENKAMP
$dbm_factory = new_dbm( type => DBM::Deep->TYPE_ARRAY );
while ( my $dbm_maker = $dbm_factory->() ) {
    my $db = $dbm_maker->();

    push @{$db}, 3, { foo => 1 };
    lives_ok {
        shift @{$db};
    } "Shift doesn't die moving references around";
    is( $db->[0]{foo}, 1, "Right hashref there" );

    lives_ok {
        unshift @{$db}, [ 1 .. 3, [ 1 .. 3 ] ];
        unshift @{$db}, 1;
    } "Unshift doesn't die moving references around";
    is( $db->[1][3][1], 2, "Right arrayref there" );
    is( $db->[2]{foo}, 1, "Right hashref there" );

    # Add test for splice moving references around
    lives_ok {
        splice @{$db}, 0, 0, 1 .. 3;
    } "Splice doesn't die moving references around";
    is( $db->[4][3][1], 2, "Right arrayref there" );
    is( $db->[5]{foo}, 1, "Right hashref there" );
}

done_testing;
__END__
{ # Make sure we do not trigger a deep recursion warning [RT #53575]
    my $w;
    local $SIG{__WARN__} = sub { $w = shift };
    my ($fh, $filename) = new_fh();
    my $db = DBM::Deep->new( file => $filename, fh => $fh, );
    my $a = [];
    my $tmp = $a;
    for(1..100) {
        ($tmp) = @$tmp = [];
    }
    ok eval {
        $db->{""} = $a;
    }, 'deep recursion in array assignment' or diag $@;
    is $w, undef, 'no warnings with deep recursion in array assignment';
}

done_testing;
