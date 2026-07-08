use Test2::V0 '!meta', '!pass';

# Regression: Join is documented as immutable/chainable -- ->join() returns a
# clone that can be extended independently. clone() shallow-copied the LOOKUP
# hash, leaving its alias arrayrefs shared, so extending the clone (re-joining a
# table already present) mutated the original join's lookup and made from()
# croak "Ambiguous table name".

use DBIx::QuickORM::Schema;
use DBIx::QuickORM::Schema::Table;
use DBIx::QuickORM::Schema::Table::Column;
use DBIx::QuickORM::Link;
use DBIx::QuickORM::Join;

my $C = 'DBIx::QuickORM::Schema::Table::Column';

my $people = DBIx::QuickORM::Schema::Table->new(
    name        => 'people',
    columns     => {id => $C->new(name => 'id', order => 1, affinity => 'numeric')},
    primary_key => ['id'],
);
my $pets = DBIx::QuickORM::Schema::Table->new(
    name    => 'pets',
    columns => {
        pet_id   => $C->new(name => 'pet_id',   order => 1, affinity => 'numeric'),
        owner_id => $C->new(name => 'owner_id', order => 2, affinity => 'numeric'),
        owner2   => $C->new(name => 'owner2',   order => 3, affinity => 'numeric'),
    },
    primary_key => ['pet_id'],
);
my $schema = DBIx::QuickORM::Schema->new(name => 's', tables => {people => $people, pets => $pets});

my $l1 = DBIx::QuickORM::Link->new(local_table => 'people', other_table => 'pets', local_columns => ['id'], other_columns => ['owner_id'], unique => 0);
my $l2 = DBIx::QuickORM::Link->new(local_table => 'people', other_table => 'pets', local_columns => ['id'], other_columns => ['owner2'], unique => 0);

subtest clone_does_not_corrupt_original => sub {
    my $j1 = DBIx::QuickORM::Join->new(schema => $schema, primary_source => $people)->left_join($l1);
    is($j1->lookup->{pets}, ['b'], "original join has one pets component");

    my $j2 = $j1->left_join($l2);    # clone + re-join the same table

    is($j1->lookup->{pets}, ['b'],      "original join's lookup is unchanged after extending the clone");
    is($j2->lookup->{pets}, ['b', 'c'], "the clone carries both pets components");

    ref_is($j1->from('pets'), $pets, "from('pets') still resolves cleanly on the original join");
};

done_testing;
