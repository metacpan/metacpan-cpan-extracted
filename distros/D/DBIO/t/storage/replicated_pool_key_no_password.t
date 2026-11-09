# ABSTRACT: A replicant's pool name (the force_pool key) never carries a password
use strict;
use warnings;

use Test::More;

use DBIO::Test;

# OFFLINE (karr k305). A replicant is named after the part of its DSN
# following dbi:Driver:, and that name is what { force_pool => $name } takes.
# The name is shown in traces and messages and kept in the pool's registry, so
# it is built without the password the DSN may carry.
#
# What this file claims:
#   1. a DSN carrying password=, pwd= or passwd= in any position is named
#      after the rest of the DSN, the other parts in their order;
#   2. the password is nowhere among the pool's replicant names;
#   3. { force_pool => $name } with that name reaches the replicant, and the
#      name with the password does not;
#   4. a DSN without a password is named as it always was.

my $SECRET = 'k305geheim';

my $schema = DBIO::Test->init_schema(
  no_deploy    => 1,
  storage_type => {
    '+DBIO::Replicated::Storage' => {
      backend_storage_class => 'DBIO::Test::Storage',
      balancer_type         => 'DBIO::Replicated::Balancer::First',
    },
  },
);
my $rstorage = $schema->storage;
$rstorage->connect_info([ 'dbi:Test:master' ]);

my @replicants = $rstorage->connect_replicants(
  [ "dbi:Test:dbname=a;password=$SECRET;host=h1" ],
  [ "dbi:Test:password=$SECRET;dbname=b;host=h2" ],
  [ "dbi:Test:dbname=c;host=h3;pwd=$SECRET" ],
  { dsn => "dbi:Test:dbname=d;Passwd=$SECRET;host=h4" },
  [ 'dbi:Test:dbname=e;host=h5', 'u', $SECRET ],
);

my @expected = map { "dbname=$_;host=h" . (ord($_) - 96) } qw( a b c d e );

my $names = $rstorage->pool->replicants;

is_deeply [ sort keys %$names ], \@expected,
  'each replicant is named after its DSN without the password part';

ok !( grep { index($_, $SECRET) >= 0 } keys %$names ),
  '... the password is among no name';

is_deeply [ map { $_->id } @replicants ], \@expected,
  '... nor in the id the replicant carries';

my $balancer = $rstorage->balancer;
is $balancer->_get_forced_pool('dbname=a;host=h1'), $names->{'dbname=a;host=h1'},
  'force_pool with the name without password finds the replicant';
eval { $balancer->_get_forced_pool("dbname=a;password=$SECRET;host=h1") };
like "$@", qr/is not a named replicant/,
  '... the name with the password is not a name';

done_testing;
