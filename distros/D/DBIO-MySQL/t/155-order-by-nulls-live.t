use strict;
use warnings;
use Test::More;

# LIVE half of karr k119: order_by with -nulls => 'first' | 'last' returns the
# rows in the order NULLS FIRST / NULLS LAST would, which MySQL and MariaDB
# cannot say themselves.
#
# WHY IT MATTERS. t/154 pins the SQL. Only a server says that `col IS NULL
# DESC, col ASC` really puts the NULLs at the front for both directions, and
# that the LIMIT / prefetch-subquery shapes keep that order. The claim: the
# four combinations of direction and nulls position give the order PostgreSQL
# gives, through plain, limited and offset selects.
#
# Works in a table of its own (mysql_k119_<pid>), dropped here. Gated like the
# other live tests: needs DBIO_TEST_MYSQL_DSN, _USER and _PASS; runs through
# whichever DBD the DSN names.

my ($dsn, $user, $pass) = @ENV{ map { "DBIO_TEST_MYSQL_${_}" } qw/DSN USER PASS/ };

plan skip_all => 'Set $ENV{DBIO_TEST_MYSQL_DSN}, _USER and _PASS to run this test'
  unless $dsn && $user;

my ($dbd) = $dsn =~ /\Adbi:(\w+):/;
plan skip_all => 'DBIO_TEST_MYSQL_DSN names neither dbi:mysql: nor dbi:MariaDB:'
  unless defined $dbd && $dbd =~ /\A(?:mysql|MariaDB)\z/;

my $TABLE = "mysql_k119_$$";

{
  package NullsLive::Schema;
  use DBIO 'Schema';
  __PACKAGE__->load_components('MySQL');
}
{
  package NullsLive::Schema::Result::Item;
  use DBIO;
  __PACKAGE__->table($TABLE);
  __PACKAGE__->add_columns(
    id => { data_type => 'integer', is_auto_increment => 1 },
    n  => { data_type => 'integer', is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
}
NullsLive::Schema->register_class(Item => 'NullsLive::Schema::Result::Item');

my $schema = NullsLive::Schema->connect($dsn, $user, $pass);
my $dbh = $schema->storage->dbh;
note sprintf 'server %s, DBD::%s', scalar $dbh->selectrow_array('SELECT VERSION()'), $dbd;

END {
  if ($dbh) {
    local ($@, $?);
    eval { local $dbh->{Warn} = 0; $dbh->do("DROP TABLE IF EXISTS `$TABLE`") };
  }
}
unless (eval { $dbh->do("DROP TABLE IF EXISTS `$TABLE`");
  $dbh->do("CREATE TABLE `$TABLE` (id INT AUTO_INCREMENT PRIMARY KEY, n INT NULL)"); 1 }) {
  my $why = "$@";
  undef $dbh;
  plan skip_all => "this account may not create a table: $why";
}

# ids 1..6; n: 3, NULL, 1, NULL, 2, 3
$schema->resultset('Item')->create({ n => $_ }) for 3, undef, 1, undef, 2, 3;

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

# ties on the first key fall back to the next entry
is join(',', map $_->id, $items->search({}, { order_by => [ { -desc => 'n', -nulls => 'last' }, { -desc => 'id' } ] })->all),
  '6,1,5,3,4,2', 'a second key breaks the ties';

done_testing;
