use strict;
use warnings;
use Test::More;
use DBI;
use DBIO::Core;
use DBIO::Schema;

# LIVE (karr k97). The counterpart of t/114-freetds-non-ascii-refused.t: over
# FreeTDS a string with a character beyond ASCII was reported as an error by
# the client library AFTER the statement had run, and the row held a blank in
# place of the value (measured 2026-10-25, U+00FC, U+20AC, U+65E5, varchar and
# univarchar). The storage refuses it before anything is sent: an exception
# naming table and column, and no row. ASCII still goes in. Skipped when the
# client library is not FreeTDS (nothing was measured there).
#
# Makes one table in the database of the DSN, named after this process, and
# drops it.

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_SYBASE_${_}" } qw/DSN USER PASS/};
plan skip_all => 'Set $ENV{DBIO_TEST_SYBASE_DSN}, _USER and _PASS to run this test'
  unless $dsn && defined $user && defined $pass;

$ENV{DBIO_SYBASE_FREETDS_NOWARN} = 1;
my $TABLE = "dbio_k97_na_$$";

{
  package T::K97NA::Result::Doc;
  use base 'DBIO::Core';
  __PACKAGE__->table($TABLE);
  __PACKAGE__->add_columns(
    id => { data_type => 'integer' },
    v  => { data_type => 'varchar',    size => 40, is_nullable => 1 },
    u  => { data_type => 'univarchar', size => 40, is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
  package T::K97NA::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->register_class(Doc => 'T::K97NA::Result::Doc');
}

my $raw = DBI->connect($dsn, $user, $pass, { RaiseError => 1, PrintError => 0, AutoCommit => 1 });
$raw->do("CREATE TABLE $TABLE (id int NOT NULL, v varchar(40) NULL, u univarchar(40) NULL)");
my $rows = sub { $raw->selectrow_array("SELECT count(*) FROM $TABLE WHERE id > 100") };

my $n = 100;
for my $storage_type (qw(DBIO::Sybase::Storage DBIO::Sybase::Storage::ASE::NoBindVars)) {
  my $short = $storage_type =~ s/.*:://r;
  my $schema = T::K97NA::Schema->clone;
  $schema->storage_type("+$storage_type");
  $schema->connection($dsn, $user, $pass);
  my $rs = $schema->resultset('Doc');

  SKIP: {
    skip "$short: not FreeTDS, nothing was measured there", 8
      unless eval { $schema->storage->_using_freetds };

    my $before = $rows->();
    for my $col (qw(v u)) {
      for my $value ("\x{fc}", "\x{20ac}", "\x{65e5}\x{672c}") {
        my $err = eval { $rs->create({ id => ++$n, $col => $value }); 1 } ? '' : "$@";
        like $err, qr/table \Q$TABLE\E, column $col: .*has a character beyond ASCII.*is refused/s,
          sprintf '%s, %s: U+%04X is refused, naming table and column', $short, $col, ord $value
          if $value eq "\x{20ac}" or $value eq "\x{fc}";
      }
    }
    is $rows->(), $before, "$short: ... and no row was written";

    ok eval { $rs->create({ id => ++$n, v => 'plain', u => 'plain' }); 1 }, "$short: ASCII goes in" or diag $@;
    my ($v) = $raw->selectrow_array("SELECT v FROM $TABLE WHERE id = $n");
    is $v, 'plain', '... and reads back';
    ok eval { $rs->create({ id => ++$n, v => undef }); 1 }, "$short: NULL goes in" or diag $@;
  }
  $schema->storage->disconnect;
}

$raw->do("DROP TABLE $TABLE");
$raw->disconnect;
done_testing;
