use warnings;
use strict;

use Test::More;

use DBIO::Test;

# karr #51: relationship_info() promotes {source} and {attrs}{accessor} to a
# documented, stable public contract (consumed e.g. by dbio-graphql when it
# walks relationships to build a schema). This test is the guard that makes the
# contract fail loudly if it ever regresses.
#
# Mock-only: init_schema with no DSN -> DBIO::Test::Storage, no real database.

my $schema = DBIO::Test->init_schema;

# has_many: Artist -> cds resolves to a resultset of zero-or-many CDs.
{
  my $info = $schema->source('Artist')->relationship_info('cds');
  is(
    $info->{source}, 'DBIO::Test::Schema::CD',
    'has_many {source} is the fully-qualified target Result class',
  );
  is(
    $info->{attrs}{accessor}, 'multi',
    'has_many {attrs}{accessor} is the multi arity marker',
  );
}

# belongs_to: CD -> artist is a single-value relationship.
{
  my $info = $schema->source('CD')->relationship_info('artist');
  is(
    $info->{source}, 'DBIO::Test::Schema::Artist',
    'belongs_to {source} is the fully-qualified target Result class',
  );
  is(
    $info->{attrs}{accessor}, 'filter',
    'belongs_to {attrs}{accessor} is the single-value (filter) arity marker',
  );
  isnt(
    $info->{attrs}{accessor}, 'multi',
    'belongs_to {attrs}{accessor} is not the multi marker (single-value side)',
  );
}

done_testing();
