package test::TestThing;

use Data::ObjectStore;

use base 'Data::ObjectStore::Container';

sub foo {
    "BAR";
}

1;
