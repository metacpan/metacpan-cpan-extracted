use strict;
use warnings;

use Test::More;
use DBIO::Test;
use DBIO::Test::Storage ();

# karr dbio-sqlite k74 -- sources() answers the source names sorted by name.
#
# It answered them in hash order, which changes with the hash seed, from one
# process to the next. Core itself turned that list into a sequence of
# statements: deploy_changelog deployed the changelog tables in the order
# sources() gave them, so the same schema was deployed in another order in
# every process.
#
# DBIO::Test::Schema registers some fifty sources; hash order does not come out
# sorted for that many by accident, so no hash seed turns this file green.
#
# Mock-only: init_schema with no DSN -> DBIO::Test::Storage, no real database.

my $schema = DBIO::Test->init_schema(no_deploy => 1);

my @sources = $schema->sources;

cmp_ok scalar @sources, '>', 20, 'the schema has enough sources to tell';

is_deeply \@sources, [ sort @sources ], 'sources come sorted by name';

is_deeply(
  [ sort @sources ],
  [ sort keys %{ $schema->source_registrations } ],
  'and they are every registered source',
);

# Scalar context keeps answering the count, as the unsorted list did -- a bare
# `sort ...` answers undef there.
is scalar( $schema->sources ), scalar @sources,
  'in scalar context sources answers how many there are';

is_deeply(
  [ DBIO::Test::Schema->sources ],
  [ sort DBIO::Test::Schema->sources ],
  'the schema class answers sorted as well',
);

is_deeply(
  [ $schema->clone->sources ],
  \@sources,
  'a cloned schema answers the same sorted list',
);

is_deeply(
  [ $schema->compose_namespace('DBIO::Test::SourcesOrderNS')->sources ],
  \@sources,
  'so does a composed namespace',
);

# A source registered at runtime takes its place by name, not at the end.
{
  package DBIO::Test::SourcesOrderThing;
  use warnings;
  use strict;
  use base qw/DBIO::Core/;
  __PACKAGE__->table('sources_order_thing');
  __PACKAGE__->add_columns(qw/id/);
  __PACKAGE__->set_primary_key('id');
}

$schema->register_class(Mmm_SourcesOrder => 'DBIO::Test::SourcesOrderThing');

is_deeply(
  [ $schema->sources ],
  [ sort @sources, 'Mmm_SourcesOrder' ],
  'a source registered at runtime is sorted in',
);

isnt +($schema->sources)[-1], 'Mmm_SourcesOrder',
  'it is not simply the last one';

# What the order is for: deploy_changelog hands one changelog table after the
# other to the storage -- the set table first, then one per tracked source, by
# source name, the same sequence in every process. Ten sources, registered out
# of order: hash order has one chance in 10! of coming out sorted.
{
  my @tracked = qw(Zulu Alpha Mike Bravo Yankee Charlie Xray Delta Whiskey Echo);

  {
    package DBIO::Test::SourcesOrderCL;
    use warnings;
    use strict;
    use base qw/DBIO::Schema/;
    __PACKAGE__->load_components('ChangeLog::Schema');
  }

  for my $moniker (@tracked) {
    my $class = "DBIO::Test::SourcesOrderCL::Result::$moniker";
    {
      no strict 'refs';
      @{"${class}::ISA"} = ('DBIO::Core');
    }
    $class->table(lc $moniker);
    $class->add_columns(qw/id/);
    $class->set_primary_key('id');
    DBIO::Test::SourcesOrderCL->register_class($moniker => $class);
  }

  my @deployed;
  {
    package DBIO::Test::SourcesOrderStorage;
    use warnings;
    use strict;
    use base qw/DBIO::Test::Storage/;
    sub deploy { push @deployed, $_[1]->source_name }
  }

  DBIO::Test::SourcesOrderCL->storage_type('+DBIO::Test::SourcesOrderStorage');
  my $cl_schema = DBIO::Test::SourcesOrderCL->connect(sub { });
  $cl_schema->storage(DBIO::Test::SourcesOrderStorage->new($cl_schema));

  $cl_schema->deploy_changelog;

  is_deeply(
    \@deployed,
    [ 'ChangeLog_Set', map { "${_}_ChangeLog" } sort @tracked ],
    'deploy_changelog deploys the changelog tables by source name',
  );
}

done_testing;
