use strict;
use warnings;
use Test::More;

# LIVE half of karr k78: order_by with -nulls => 'first' | 'last' returns the
# rows in the order NULLS FIRST / NULLS LAST would, which SQL Server cannot say
# itself. Counterpart of t/113 (offline).
#
# WHY IT MATTERS. t/113 pins the SQL. Only a server says that the CASE WHEN
# .. IS NULL sort key really puts the NULLs at the front or the back for both
# directions, and that the ROW_NUMBER() OVER (ORDER BY ..) limit, with its
# reversed outer parts, keeps that order. The claim: the four combinations of
# direction and nulls position give the order PostgreSQL gives, plain, with
# rows, and with rows + offset.
#
# Works in a table of its own (dbio_mssql_k78_<pid>_<n>), dropped here. Runs
# for every access path whose DSN is set.

my @paths = grep { $_->[0] && defined $_->[1] } (
  [ @ENV{qw/DBIO_TEST_MSSQL_ODBC_DSN DBIO_TEST_MSSQL_ODBC_USER DBIO_TEST_MSSQL_ODBC_PASS/}, 'odbc'   ],
  [ @ENV{qw/DBIO_TEST_MSSQL_DSN      DBIO_TEST_MSSQL_USER      DBIO_TEST_MSSQL_PASS/},      'sybase' ],
);
plan skip_all => 'Set $ENV{DBIO_TEST_MSSQL_ODBC_DSN} (or DBIO_TEST_MSSQL_DSN), _USER and _PASS to run this test'
  unless @paths;

my $seq = 0;
for my $p (@paths) {
  my ($dsn, $user, $pass, $label) = @$p;
  my $TABLE = "dbio_mssql_k78_${$}_" . ++$seq;

  my $sc = "K78Live::${label}::Schema";
  eval "package $sc; use DBIO 'Schema'; __PACKAGE__->load_components('MSSQL'); 1" or die $@;
  my $rc = "${sc}::Result::Item";
  eval "package $rc; use base 'DBIO::Core'; 1" or die $@;
  $rc->table($TABLE);
  $rc->add_columns(
    id => { data_type => 'integer', is_auto_increment => 1 },
    n  => { data_type => 'integer', is_nullable => 1 },
  );
  $rc->set_primary_key('id');
  $sc->register_class(Item => $rc);

  my $schema = $sc->connect($dsn, $user, $pass);
  my $dbh = $schema->storage->dbh;

  my $cleanup = sub {
    local ($@, $?);
    eval { $dbh->do("IF OBJECT_ID('$TABLE') IS NOT NULL DROP TABLE [$TABLE]") };
  };
  $cleanup->();
  unless (eval { $dbh->do("CREATE TABLE [$TABLE] (id INT IDENTITY(1,1) PRIMARY KEY, n INT NULL)"); 1 }) {
    diag "$label: this account may not create a table: $@";
    next;
  }

  my $ok = eval {
    # ids 1..6; n: 3, NULL, 1, NULL, 2, 3
    $schema->resultset('Item')->create({ n => $_ }) for 3, undef, 1, undef, 2, 3;

    my $items = $schema->resultset('Item');
    my $ns = sub {
      my ($order, %attrs) = @_;
      return join ',', map { defined $_ ? $_ : 'N' }
        map $_->n, $items->search({}, { order_by => [ $order, 'id' ], %attrs })->all;
    };

    is $ns->({ -asc  => 'n', -nulls => 'first' }), 'N,N,1,2,3,3', "$label: asc, nulls first";
    is $ns->({ -asc  => 'n', -nulls => 'last'  }), '1,2,3,3,N,N', "$label: asc, nulls last";
    is $ns->({ -desc => 'n', -nulls => 'first' }), 'N,N,3,3,2,1', "$label: desc, nulls first";
    is $ns->({ -desc => 'n', -nulls => 'last'  }), '3,3,2,1,N,N', "$label: desc, nulls last";

    is $ns->({ -asc  => 'n', -nulls => 'first' }, rows => 3), 'N,N,1', "$label: rows, asc nulls first";
    is $ns->({ -asc  => 'n', -nulls => 'last'  }, rows => 3), '1,2,3', "$label: rows, asc nulls last";
    is $ns->({ -desc => 'n', -nulls => 'first' }, rows => 3), 'N,N,3', "$label: rows, desc nulls first";
    is $ns->({ -desc => 'n', -nulls => 'last'  }, rows => 3), '3,3,2', "$label: rows, desc nulls last";

    is $ns->({ -asc  => 'n', -nulls => 'first' }, rows => 3, offset => 2), '1,2,3', "$label: rows+offset, asc nulls first";
    is $ns->({ -asc  => 'n', -nulls => 'last'  }, rows => 3, offset => 2), '3,3,N', "$label: rows+offset, asc nulls last";
    is $ns->({ -desc => 'n', -nulls => 'first' }, rows => 3, offset => 2), '3,3,2', "$label: rows+offset, desc nulls first";
    is $ns->({ -desc => 'n', -nulls => 'last'  }, rows => 3, offset => 2), '2,1,N', "$label: rows+offset, desc nulls last";

    # ties on the first key fall back to the next entry
    is join(',', map $_->id, $items->search({}, { order_by => [ { -desc => 'n', -nulls => 'last' }, { -desc => 'id' } ] })->all),
      '6,1,5,3,4,2', "$label: a second key breaks the ties";
    1;
  };
  my $err = $@;
  $cleanup->();
  $schema->storage->disconnect;
  die $err unless $ok;
}

done_testing;
