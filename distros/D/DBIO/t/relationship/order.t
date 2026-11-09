use strict;
use warnings;

use Test::More;
use DBIO::Test;

# karr dbio-sqlite k74 -- relationships() answers the names sorted by name.
#
# It answered them in hash order, and that order changes with the hash seed,
# from one process to the next. Whoever walks the list to write text -- a
# driver's install_ddl turning each belongs_to into a FOREIGN KEY -- wrote
# another text in every process unless it sorted the list itself; two drivers
# did, the others did not.
#
# Sixteen names, declared out of order: hash order has one chance in 16! of
# coming out sorted, so no hash seed turns this file green by accident. The
# names pin a plain string sort -- 'Bravo' sorts before every lowercase name,
# 'mike_10' before 'mike_9'.
#
# Mock-only: init_schema with no DSN -> DBIO::Test::Storage, no real database.

my @declared = qw(
  zulu alpha mike_9 Bravo yankee charlie xray delta
  whiskey mike_10 echo victor foxtrot uniform golf tango
);

{
  package DBIO::Test::RelOrderSpoke;
  use warnings;
  use strict;
  use base qw/DBIO::Core/;
  __PACKAGE__->table('relorder_spoke');
  __PACKAGE__->add_columns(qw/id hub_id/);
  __PACKAGE__->set_primary_key('id');
}

{
  package DBIO::Test::RelOrderHub;
  use warnings;
  use strict;
  use base qw/DBIO::Core/;
  __PACKAGE__->table('relorder_hub');
  __PACKAGE__->add_columns(qw/id/);
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->has_many($_ => 'DBIO::Test::RelOrderSpoke', 'hub_id')
    for @declared;
}

my @sorted = sort @declared;

isnt "@declared", "@sorted", 'the names are declared out of order';

is_deeply(
  [ DBIO::Test::RelOrderHub->relationships ],
  \@sorted,
  'relationships of an unregistered result class come sorted by name',
);

my $schema = DBIO::Test->init_schema(no_deploy => 1);
$schema->register_class(relorder_spoke => 'DBIO::Test::RelOrderSpoke');
$schema->register_class(relorder_hub   => 'DBIO::Test::RelOrderHub');

my $hub = $schema->source('relorder_hub');

is_deeply(
  [ $hub->relationships ],
  \@sorted,
  'relationships of a registered source come sorted by name',
);

is_deeply(
  [ $schema->clone->source('relorder_hub')->relationships ],
  \@sorted,
  'the source of a cloned schema answers the same sorted list',
);

is_deeply(
  [ $schema->compose_namespace('DBIO::Test::RelOrderNS')
      ->source('relorder_hub')->relationships ],
  \@sorted,
  'so does the source of a composed namespace',
);

# A relationship added at runtime takes its place by name, not at the end.
$hub->add_relationship(
  lima => 'DBIO::Test::RelOrderSpoke',
  { 'foreign.hub_id' => 'self.id' },
  { accessor => 'multi' },
);

is_deeply(
  [ $hub->relationships ],
  [ sort @declared, 'lima' ],
  'a relationship added at runtime is sorted in',
);

# The order is all that changed: every name is still there and answers as
# before.
for my $rel (@declared, 'lima') {
  ok $hub->has_relationship($rel), "has_relationship('$rel')";
  is $hub->relationship_info($rel)->{source}, 'DBIO::Test::RelOrderSpoke',
    "relationship_info('$rel') names the related class";
}

# Scalar context keeps answering the count, as the unsorted list did -- a bare
# `return sort ...` answers undef there.
is scalar( $hub->relationships ), @declared + 1,
  'in scalar context relationships answers how many there are';

ok !$hub->has_relationship('november'), 'an undeclared name is no relationship';
is $hub->relationship_info('november'), undef,
  'relationship_info of an undeclared name is undef';

done_testing;
