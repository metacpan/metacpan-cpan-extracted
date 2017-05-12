# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl DBIx-bind_param_inline.t'

use DBI;

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 4;
BEGIN { use_ok('DBIx::bind_param_inline') };


#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

-d "/tmp/" or die "/tmp directory nonexistent";
-w "/tmp/" or die "/tmp directory nonwritable";
my $dbh = DBI->connect("dbi:SQLite:dbname=:memory:",'','');
# END { # unlink "/tmp/DBIx_bind_param_inline_TEST_$$" };

our ($foo, $bar, $baz);

$dbh->do( "$_") for grep { /\w/ } split ";;", <<'SQL';
CREATE TABLE mytable (
  foo TEXT, bar TEXT, baz TEXT
);;
INSERT INTO mytable VALUES ( 27, 'chumba','wumba' );;
INSERT INTO mytable VALUES ( 28, 'zig','zag' );;
SQL

$dbh->{RaiseError} = 1;


  # qq style -- escape rods of Asclepius
  my $sth = prepare_inline($dbh, <<SQL);
  SELECT  baz  from mytable WHERE foo = \$foo AND bar = ?
SQL
  # q style -- noninterpolative
  my $sth2 = prepare_inline($dbh, <<'SQL');
  INSERT INTO mytable (foo, bar, baz) VALUES ($foo, $bar, $baz)
SQL
  my $sth3 = prepare_inline($dbh, <<'SQL');
  SELECT bar, baz FROM mytable where foo = $foo
SQL
    ($foo, $bar, $baz) = (29, 33, 41);
  $sth2->execute(); #placeholders get bound for you
 $foo = 27;
 $sth3->execute;
 my $aref = $sth3->fetch;
 is_deeply($aref, [ 'chumba', 'wumba'], "SELECT with inlined placeholder"); 
$foo = 28; $sth->execute('zig');
 $aref = $sth->fetch;
 is_deeply($aref, [qw/zag/], "hybrid placeholders"); 
$foo = 29; $sth->execute(33);
 $aref = $sth->fetch;
 is_deeply($aref, [41], "insert with inlined placeholders"); 


