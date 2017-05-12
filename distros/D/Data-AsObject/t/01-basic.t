#!perl -T

use strict;
use warnings;

use lib q(lib);

use Test::More tests => 13;
use Test::Deep;
use Data::AsObject qw(dao);

my $data = {
    test => 1,
    blah => [1,2,3],
    kaboom => {one => 'true', two => 'false'},
    bong => [
        { town => 'sliven', district => 'center', },
        { town => 'sofia', district => 'druzhba', },
        { town => 'sofia', district => 'bakston', },
    ],
    'xml:thingy' => 2,
    'meaning-of-life' => 42,
};

### INITIALIZATION ###

# construct from hashref
my $dao = dao $data;
isa_ok($dao, "Data::AsObject::Hash");

# construct from arrayref
my $dao_array = dao $data->{blah};
isa_ok($dao_array, "Data::AsObject::Array");

# construct from object
my $dao_object = dao $dao;
isa_ok($dao_object, "Data::AsObject::Hash");


### DATA ACCESS ###

is         ( $dao->test,          1,                 "Test data access 1" );
cmp_deeply ( $dao->blah,          noclass([1,2,3]),  "Test data access 2" );
is         ( $dao->blah(0),       1,                 "Test data access 3" );
is         ( $dao->blah->get(0),  1,                 "Test data access 4" );
is         ( $dao->bong(0)->town, 'sliven',          "Test data access 5" );

### ARRAYREF DEREFERENCING ###

is_deeply([$dao->blah->list], [1,2,3], "Dereferencing arrayrefs");
my @bong = $dao->bong->list;
isa_ok($bong[0], "Data::AsObject::Hash");

### ASSIGNING ###

$dao->{newcomer} = "taralezh";
is( $dao->newcomer, "taralezh", "Test assigning" );

### COLONS AND DASHES IN HASH KEY ###

is( $dao->xml_thingy,       2,  "Test columns in hash key" );
is( $dao->meaning_of_life,  42, "Test dashes in hash key"  );
