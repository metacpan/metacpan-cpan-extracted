use strict;
use warnings;
use Test::More;

# LIVE half of karr k123 (t/175 has the offline half): populate in void context
# binds text the way create does.
#
# WHY IT MATTERS. Under DBD::mysql with mysql_enable_utf8mb4 a string held in
# Perl's 8-bit form ("\x{fc}", not flagged as characters) goes out as the
# single byte 0xFC and the server refuses it. The driver fixed that for the
# statements bound one by one (karr k120) but populate in void context takes
# another path (execute_for_fetch) that never ran that fix. Claims, on every
# DBD installed:
#   1. populate in void context stores "\x{fc}" and reads u-umlaut back;
#   2. a create of the same value reads back the same -- both paths agree;
#   3. the bytes of a blob column go in as they are on both paths.
# Works in a table of its own, created and dropped here.

my ($dsn, $user, $pass) = @ENV{ map { "DBIO_TEST_MYSQL_${_}" } qw/DSN USER PASS/ };

plan skip_all => 'Set $ENV{DBIO_TEST_MYSQL_DSN}, _USER and _PASS to run this test'
  unless $dsn && $user;

use DBI;

my $TABLE = "dbio_k123_$$";
my $n = 0;

sub schema_for {
  my ($dbd, $attrs) = @_;
  my $ns = 'K123Live::V' . ++$n;
  eval "package $ns; use DBIO 'Schema'; __PACKAGE__->load_components('MySQL'); 1" or die $@;
  my $class = "${ns}::Result::T";
  eval "package $class; use DBIO 'Core', -mysql; 1" or die $@;
  $class->table($TABLE);
  $class->add_columns(
    id  => { data_type => 'int' },
    txt => { data_type => 'varchar', size => 20, is_nullable => 1 },
    bin => { data_type => 'blob', is_nullable => 1 },
  );
  $class->set_primary_key('id');
  $ns->register_class(T => $class);
  (my $d = $dsn) =~ s/\Adbi:\w+:/dbi:$dbd:/;
  return $ns->connect($d, $user, $pass, $attrs);
}

my $raw = DBI->connect($dsn, $user, $pass, { RaiseError => 1, PrintError => 0 });
END { if ($raw) { local ($@, $?); eval { $raw->do("DROP TABLE IF EXISTS `$TABLE`") } } }

my $ran = 0;
for my $case (
  [ mysql   => { mysql_enable_utf8mb4 => 1 } ],
  [ MariaDB => {} ],
) {
  my ($dbd, $attrs) = @$case;
  unless (eval { require "DBD/$dbd.pm"; 1 }) { diag "DBD::$dbd not installed, skipped"; next }
  $ran++;
  $raw->do("DROP TABLE IF EXISTS `$TABLE`");
  $raw->do("CREATE TABLE `$TABLE` (id INT PRIMARY KEY, txt VARCHAR(20) CHARACTER SET utf8mb4, bin BLOB)");

  my $schema = schema_for($dbd, $attrs);
  my $rs = $schema->resultset('T');
  my $latin = "\x{fc}";
  my $bytes = join '', map { chr } 0 .. 255;
  ok !utf8::is_utf8($latin), "$dbd: the test value is the 8-bit form";

  my $ok = eval {
    $rs->populate([
      { id => 1, txt => $latin,     bin => $bytes },
      { id => 2, txt => "a$latin",  bin => undef },
    ]);
    1;
  };
  ok $ok, "$dbd: 1: populate in void context runs" or diag $@;
  ok !utf8::is_utf8($latin), "$dbd: ... the caller's value is not changed";
  my $row = $rs->find(1);
  is $row && $row->txt, "\x{fc}", "$dbd: ... and the text reads back as u-umlaut";
  my $row2 = $rs->find(2);
  is $row2 && $row2->txt, "a\x{fc}", "$dbd: ... on the second row as well";

  $rs->create({ id => 3, txt => $latin, bin => $bytes });
  is $rs->find(3)->txt, "\x{fc}", "$dbd: 2: create reads back the same text";

  is $rs->find(1) && $rs->find(1)->bin, $bytes, "$dbd: 3: a blob column keeps its 256 bytes through populate";
  is $rs->find(3)->bin, $bytes, "$dbd: ... and through create";
  $schema->storage->disconnect;
}
plan skip_all => 'neither DBD::mysql nor DBD::MariaDB is installed' unless $ran;
done_testing;
