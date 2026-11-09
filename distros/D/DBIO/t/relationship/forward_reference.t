use strict;
use warnings;

use Test::More;
use Test::Exception;
use DBIO::Test;
use DBIO::ResultSource::Table;

# Property under test (ADR 0054): add_relationship performs NO definition-time
# resolution of the related source. A source that IS registered with a schema
# must be able to declare a relationship to a foreign source that is NOT yet
# registered -- the forward/circular-reference case that is normal during
# schema composition -- without throwing, and the relationship must be recorded.
#
# This is exactly the property the old (disabled) eager _resolve_join block in
# add_relationship would break: it resolves the far side via
# schema->source($name), which throws for any source not yet registered.
# Reactivating that block turns this test red.

my $schema = DBIO::Test->init_schema(no_deploy => 1);

my $foo = DBIO::ResultSource::Table->new({ name => 'foo' });
$foo->add_columns(
  id     => { data_type => 'integer' },
  bar_id => { data_type => 'integer' },
);
$foo->set_primary_key('id');
$schema->register_source(Foo => $foo);

# NotYetRegisteredBar is deliberately never registered with $schema.
lives_ok {
  $schema->source('Foo')->add_relationship(
    'bar', 'NotYetRegisteredBar', { 'foreign.id' => 'self.bar_id' },
  );
} 'add_relationship to a not-yet-registered foreign source does not throw';

ok $schema->source('Foo')->has_relationship('bar'),
  'the forward-reference relationship is recorded';

is $schema->source('Foo')->relationship_info('bar')->{source},
  'NotYetRegisteredBar',
  'the relationship points at the (unresolved) foreign source name';

done_testing;
