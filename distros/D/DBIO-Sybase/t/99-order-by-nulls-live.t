use strict;
use warnings;
use Test::More;

# LIVE half of karr k95: order_by with -nulls => 'first' | 'last' returns the
# rows in the order NULLS FIRST / NULLS LAST would, which ASE cannot say
# itself.
#
# WHY IT MATTERS. t/98 pins the SQL. Only a server says that the CASE sort in
# front of the column really puts the NULLs at the front or the back for both
# directions, and that the limit shapes keep that order: rows alone is SET
# ROWCOUNT, rows with offset is the GenericSubQ slice, which renders the
# order_by again and compares NULLs itself. The claim: the four combinations
# of direction and nulls position give the order PostgreSQL gives, through
# plain, limited and offset selects.
#
# Works in a table of its own (dbio_k95_<pid>) in the database of the DSN,
# dropped here; needs a login allowed to create a table. Gated like the other
# live tests: DBIO_TEST_SYBASE_DSN, _USER and _PASS.

my ($dsn, $user, $pass) = @ENV{ map { "DBIO_TEST_SYBASE_${_}" } qw/DSN USER PASS/ };

plan skip_all => 'Set $ENV{DBIO_TEST_SYBASE_DSN}, _USER and _PASS to run this test.'
  unless $dsn && $user;

my $TABLE = "dbio_k95_$$";

{
  package NullsLive::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('Sybase');
}
{
  package NullsLive::Schema::Result::Item;
  use base 'DBIO::Core';
  __PACKAGE__->table($TABLE);
  __PACKAGE__->add_columns(
    id => { data_type => 'integer' },
    n  => { data_type => 'integer', is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
}
NullsLive::Schema->register_class(Item => 'NullsLive::Schema::Result::Item');

my $schema = NullsLive::Schema->connect($dsn, $user, $pass);
my $dbh = $schema->storage->dbh;
note 'client library: ' . ( $dbh->{syb_oc_version} || '(unknown)' );

END {
  if ($dbh) {
    local ($@, $?);
    eval { local $dbh->{PrintError} = 0; $dbh->do("drop table $TABLE") };
  }
}

unless (eval { $dbh->do("create table $TABLE (id int not null primary key, n int null)"); 1 }) {
  my $why = "$@";
  undef $dbh;
  plan skip_all => "this account may not create a table: $why";
}

# ids 1..6; n: 3, NULL, 1, NULL, 2, 3
my @n = (3, undef, 1, undef, 2, 3);
$schema->resultset('Item')->create({ id => $_ + 1, n => $n[$_] }) for 0 .. $#n;

my $items = $schema->resultset('Item');
sub ns {
  my ($order, %attrs) = @_;
  return join ',', map { defined $_ ? $_ : 'N' }
    map $_->n, $items->search({}, { order_by => [ $order, 'id' ], %attrs })->all;
}

is ns({ -asc  => 'n', -nulls => 'first' }), 'N,N,1,2,3,3', 'asc, nulls first';
is ns({ -asc  => 'n', -nulls => 'last'  }), '1,2,3,3,N,N', 'asc, nulls last';
is ns({ -desc => 'n', -nulls => 'first' }), 'N,N,3,3,2,1', 'desc, nulls first';
is ns({ -desc => 'n', -nulls => 'last'  }), '3,3,2,1,N,N', 'desc, nulls last';

is ns({ -asc => 'n', -nulls => 'first' }, rows => 3), 'N,N,1', 'limited, nulls first';
is ns({ -asc => 'n', -nulls => 'last'  }, rows => 3, offset => 2), '3,3,N', 'limited with offset, nulls last';
is ns({ -desc => 'n', -nulls => 'first' }, rows => 2, offset => 1), 'N,3', 'limited with offset, desc, nulls first';

# ties on the first key fall back to the next entry
is join(',', map $_->id, $items->search({}, { order_by => [ { -desc => 'n', -nulls => 'last' }, { -desc => 'id' } ] })->all),
  '6,1,5,3,4,2', 'a second key breaks the ties';

done_testing;
