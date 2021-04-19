use Test::More;
use lib 't/lib';
use Art::World;
use Art::World::Util;
use Test::Art::World;
use feature qw( postderef say );
no warnings qw( experimental::postderef );

my $munnies = 9_999;

my $collector1 = Art::World
  ->new_collector(
    name => Art::World::Util->new_person->fake_name,
    money => $munnies,
    id => 3
  );

my $collector2 = Art::World
  ->new_collector(
    name => Art::World::Util->new_person->fake_name,
    money => $munnies + 1_000,
    id => 4
  );

my $homogenic_artist = Art::World->new_artist(
  name => Art::World::Util->new_person->fake_name,
  collectors => [ $collector1, $collector2 ]
);

ok $homogenic_artist->is_homogenic, 'Artist status is homogenic since it has collectors';

my $artwork = Art::World->new_artwork(
    creator => [ $homogenic_artist ]  ,
    title   => 'Destroy capitalism',
    value   => 10_000,
    owner   => [ $collector1, $collector2 ],
  );

my $artwork2 = Art::World->new_artwork(
  creator => [ $homogenic_artist ]  ,
  owner   => [ $collector2 ],
  title   => 'Money spoils everything',
  value   => 12_000,
);

my $artwork3 = Art::World->new_artwork(
  creator => [ $homogenic_artist ],
  title   => 'Collectors sucks',
  value   => 12_000,
  # Note: no owner here so we will test that it is set by default
 );

push $collector1->collection->@*, $artwork;
push $collector2->collection->@*, $artwork;

my $taw = Test::Art::World->new;
ok $taw->is_artist_creator( $homogenic_artist, $artwork3 ),
  'One of the artwork creator is ' . $homogenic_artist->name;

is $homogenic_artist->name, $artwork3->owner->[0]->name, "Default owner of an artwork is it's creator";

$munnies = 100_000;

my $collector = Art::World
  ->new_collector(
    name => Art::World::Util->new_person->fake_name,
    money => $munnies,
    id => 3
  );

isa_ok $collector, 'Art::World::Agent';
can_ok $collector, qw/acquire participate pay/;

ok $collector->money, 'Collector got a money attr';
ok $collector->collection, 'Collector got a collection attr';

is $collector->money, $munnies, 'Collector money value is valid';

ok $collector->does('Art::World::Buyer'), 'Collector does role Buyer';

# Test that each owner received the correct amount of money ( their own part => value of the artwork / number of owners )
is $collector1->money, 9_999, '$collector1 have some money before sell';
is $collector2->money, 10_999, '$collector2 have some money before sell';

my $check = 'Checking collector\'s collection items length';

is scalar $collector->collection->@*, 0, $check;
is scalar $collector1->collection->@*, 1, $check;
is scalar $collector2->collection->@*, 1, $check;

ok $collector->acquire( $artwork ),
  'Collector added an artwork to their collection';

is scalar $collector->collection->@*, 1, $check;
is scalar $collector1->collection->@*, 0, $check;
is scalar $collector2->collection->@*, 0, $check;

is $collector1->money, 14_999, '$collector1 have more money after sell';
is $collector2->money, 15_999, '$collector2 have more money after sell';

ok $collector->acquire( $artwork2 ),
  'Collector added a second artwork to their collection';

is $collector->money, 78_000, 'Check new collector\'s fortune';
is $collector2->money, 15_999 + $artwork2->value, 'Check seller\'s fortune';

foreach ( $collector->collection->@* )  {
  isa_ok $_, 'Art::World::Artwork';
}

is scalar $collector->collection->@*, 2, 'Checked length of collector\'s collection';

ok $taw->is_artist_creator( $homogenic_artist, $artwork3 ),
  'One of the artwork creator is ' . $homogenic_artist->name;

# Owner change
my $seller_name = $artwork3->owner->[0]->name;
$collector->acquire( $artwork3 );
my $buyer_name = $artwork3->owner->[0]->name;

ok $taw->is_artist_creator( $homogenic_artist, $artwork3 ),
  'One of the artwork creator is ' . $homogenic_artist->name;

# The artist received the correct amount of money (100%)
is $homogenic_artist->money, 12_000, 'Checking the artist has been paid';

isnt $seller_name, $buyer_name, 'Artwork owner changed';

ok $taw->is_artist_creator( $homogenic_artist, $artwork3 ),
  'One of the artwork creator is ' . $homogenic_artist->name;

is scalar $collector->collection->@*, 3, 'Length of collector\'s collection increased';

my $collector3 = Art::World
  ->new_collector(
    name => Art::World::Util->new_person->fake_name,
    money => $munnies + 9_000,
    id => 5
  );

# TODO coinvestors money should be initialized automatically see #85
# Test the case when there are many buyers.
my $coinvestors = Art::World
  ->new_coinvestor(
    members => [ $collector2, $collector3 ],
    money => $collector2->money + $collector3->money,
    # BUG the coinvestors collection is not necessarily empty on creation and should be initialized appropriately
    # BUG more complex collection update process necessary
    name => 'Weird Art Investors',
   );

can_ok $coinvestors, qw/acquire pay members/;

is scalar $coinvestors->collection->@*, 0, 'Coinvestors didn\'t invested yet';

$coinvestors->acquire({ art => $collector->collection->[2], collective => $coinvestors });

is scalar $collector->collection->@*, 2, 'Seller got a smaller collection';
is scalar $coinvestors->collection->@*, 1, 'Coinvestors invested';

# TODO p $collector money;
# TODO p $coinvestors->members->[0]->money;
# TODO p $coinvestors->members->[1]->money;

my $coinvestors2 = Art::World
  ->new_coinvestor(
    members => [ $collector, $collector1 ],
    money => $collector->money + $collector1->money,
    name => 'Such Investment',
   );

$coinvestors2->acquire({ art => $coinvestors->collection->[0], collective => $coinvestors2 });


done_testing;
