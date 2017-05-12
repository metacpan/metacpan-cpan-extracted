# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 15 };
use Data::StackedHash;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

# 2 initialize with empty hash
tie %h, Data::StackedHash;
ok(not exists $h{'a'});
untie %h;

# 3 create with hash reference
tie %h, Data::StackedHash, { 'a'=>1, 'b'=>2 };
ok($h{'a'}, 1);

# 4 push empty hash on top
tied(%h)->push;
ok($h{'a'},1);

# 5 push non-empty hash on top
tied(%h)->push({'a'=>2, 'b'=>3});
ok($h{'a'}, 2);

# 6 delete
ok(delete $h{'b'}, 3);

# 7 assignment
$h{'b'} = 4;
ok($h{'b'}, 4);

# 8 fetch_all
$x = join '', tied(%h)->fetch_all('b');
ok($x, '42');

# 9 delete_all
$x = join '', tied(%h)->delete_all('b');
ok($x, '42');

# 10,11 exists
ok(exists $h{'a'});
ok(not exists $h{'b'});

# 12 pop and restore previous
tied(%h)->pop;
ok($h{'a'}, 1);

untie %h;

# 13 keys
tie %h, Data::StackedHash, { 'a'=>1, 'b'=>2};
tied(%h)->push({'c'=>3});
$x = join '', sort keys %h;
ok($x, 'abc');

# 14 values
$x = join '', sort values %h;
ok($x, '123');

# 15 count
ok(tied(%h)->count('a'), 1);
