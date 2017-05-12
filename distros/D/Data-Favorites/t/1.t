# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 16;
BEGIN { use_ok('Data::Favorites') };
require_ok('Data::Favorites');

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my @f;
my $Stamp = 34;
sub stamper { return ++$Stamp; }

use Data::Favorites;
use Data::Dumper;
my $faves = new Data::Favorites( \&stamper );
ok($faves, 'faves created');
ok(0 == (scalar $faves->favorites()), 'empty faves is really empty');

ok((not defined $faves->tally("huey")), 'unknown item has undef tally');
ok(1 == $faves->tally("huey", 1), 'simple tally sticks');
ok($Stamp == $faves->fresh("huey"), 'custom stamper function worked');
ok(4 == $faves->tally("louie", 4), 'another fave');
ok(2 == $faves->tally("dewey", 2), 'new item can get multiple tallies');
ok(1 == $faves->tally("huey"), 'checking tally does not change tally');
ok(3 == $faves->tally("huey", 2), 'tallies accumulate');

# huey = 3 (38); dewey = 2 (37); louie = 4 (36)
# huey is most fresh, and middle tallies
# dewey is middle fresh, and least tallies
# louie is least fresh, but most tallies

@f = $faves->favorites(2);
ok(2 == @f, 'returned some items');
@f = $faves->favorites();
ok(3 == @f, 'returned all items');
ok("louie" eq $f[0], 'most tallies wins the race');
$faves->decay(2);
ok(2 == $faves->favorites(), 'decay culls a zero-tally item');
$faves->clamp(37);
ok(1 == $faves->favorites(), 'clamp culls a stale item');
