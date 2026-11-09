use strict;
use warnings;

use Test::More;
use DBIO::Optional::Dependencies ();

# LIVE ONLY (karr k55), the counterpart of the BOOLEAN block of t/45. The catalog
# keeps the text of a DEFAULT as written (measured on Db2 12.1.5): DEFAULT '1'
# reads '1', 1 reads 1, TRUE reads TRUE, 'true' reads 'true'. install_ddl writes a
# class value '1' bare (DEFAULT 1), so
#
#   1. a class with BOOLEAN defaults '1', 'true', 1, 0 and \'TRUE' installed by
#      install_ddl has an empty diff afterwards (this held already; pinned), and
#   2. a table made by hand with DEFAULT '1' / '0' / 1 / TRUE / FALSE, compared
#      with the class that says the same (what DBIO::Generate writes from the live
#      model), got SET DEFAULT 1 / 0 for the quoted ones -- a default that was
#      there. Introspect::Columns reads a quoted number of a BOOLEAN as the number,
#      so that diff is empty.
#
# Own table: dbio_k55b_<pid>.

plan skip_all => 'Test needs ' . DBIO::Optional::Dependencies->req_missing_for ('test_rdbms_db2')
  unless DBIO::Optional::Dependencies->req_ok_for ('test_rdbms_db2');

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_DB2_${_}" } qw/DSN USER PASS/};

plan skip_all => 'Set $ENV{DBIO_TEST_DB2_DSN}, _USER and _PASS to run this test'
  unless ($dsn && $user);

my $T = "dbio_k55b_$$";

{
  package DBIO::Test::K55B::Schema;
  use strict; use warnings;
  use base 'DBIO::Schema';
  use DBIO::Core ();
  __PACKAGE__->load_components('DB2');

  my $class = 'DBIO::Test::K55B::T';
  no strict 'refs';
  @{"${class}::ISA"} = ('DBIO::Core');
  $class->table($T);
  $class->add_columns(
    id => { data_type => 'integer', is_auto_increment => 1 },
    a  => { data_type => 'boolean', default_value => '1' },
    b  => { data_type => 'boolean', default_value => 'true' },
    c  => { data_type => 'boolean', default_value => 1 },
    d  => { data_type => 'boolean', default_value => 0 },
    e  => { data_type => 'boolean', default_value => \'TRUE' },
    f  => { data_type => 'boolean', default_value => '0' },
    g  => { data_type => 'boolean', default_value => \'FALSE' },
  );
  $class->set_primary_key('id');
  __PACKAGE__->register_class(T => $class);
}

use DBIO::DB2::Deploy;

my $schema = DBIO::Test::K55B::Schema->connect($dsn, $user, $pass);

my $dbh = eval { $schema->storage->dbh }
  or plan skip_all => "Cannot reach DB2: $@";

my $deploy = DBIO::DB2::Deploy->new(schema => $schema);

my $COMPARE_SCHEMA = "DBIO_TEST_$$";
sub drop_table { local $dbh->{PrintError} = 0; eval { $dbh->do(qq{DROP TABLE "$T"}) } }
END {
  if ($dbh && $dbh->{Active}) {
    drop_table();
    my ($n) = eval { $dbh->selectrow_array(
      'SELECT COUNT(*) FROM syscat.schemata WHERE schemaname = ?', undef, $COMPARE_SCHEMA) };
    $deploy->_drop_test_schema($dbh, $COMPARE_SCHEMA) if $n;
  }
}

sub ops { my $diff = $deploy->diff; return ($diff, scalar @{ $diff->operations }) }

drop_table();

# --- 1. install_ddl: the follow-up diff is empty ----------------------------------
{
  my $ddl = DBIO::DB2::DDL->install_ddl($schema);
  like $ddl, qr/"a" BOOLEAN NOT NULL DEFAULT 1,/, "setup: class '1' is written bare";
  $dbh->do($_) for DBIO::SQL::Util::_split_statements($ddl);
  my ($diff, $n) = ops();
  is $n, 0, 'after install_ddl the diff is empty' or diag $diff->as_sql;
  $dbh->do(qq{INSERT INTO "$T" ("id") VALUES (DEFAULT)});
  my ($row) = $dbh->selectrow_array(
    qq{SELECT COUNT(*) FROM "$T" WHERE "a" AND "b" AND "c" AND NOT "d" AND "e" AND NOT "f" AND NOT "g"});
  is $row, 1, '... and the row holds the declared defaults';
}
drop_table();

# --- 2. made by hand with the quoted forms, the class says the same ------------------
$dbh->do(qq{CREATE TABLE "$T" ("id" INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY (START WITH 1, INCREMENT BY 1), }
  . q{"a" BOOLEAN NOT NULL DEFAULT '1', "b" BOOLEAN NOT NULL DEFAULT 'true', "c" BOOLEAN NOT NULL DEFAULT 1, }
  . q{"d" BOOLEAN NOT NULL DEFAULT '0', "e" BOOLEAN NOT NULL DEFAULT TRUE, "f" BOOLEAN NOT NULL DEFAULT '0', }
  . qq{"g" BOOLEAN NOT NULL DEFAULT FALSE, PRIMARY KEY ("id"))});
{
  my ($diff, $n) = ops();
  is $n, 0, q{a table with DEFAULT '1' / '0' / 1 / TRUE / FALSE against the class: the diff is empty}
    or diag $diff->as_sql;
}

drop_table();
done_testing;
