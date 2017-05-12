#!perl -I./t

$| = 1;

use strict;
use warnings;
use DBI();
use DBD_TEST();
use Time::HiRes qw(gettimeofday tv_interval);

use Test::More;

if (defined $ENV{DBI_DSN}) {
  plan tests => 33;
} else {
  plan skip_all => 'Cannot test without DB info';
}

pass('Large insert tests');

my $dbh = DBI->connect or die "Connect failed: $DBI::errstr\n";
pass('Database connection created');

my $tbl = $DBD_TEST::table_name;

my $MAX_ROWS = 200;

ok( DBD_TEST::tab_create( $dbh ),"Create table $tbl");

my $sth = $dbh->prepare("SELECT * FROM $tbl",
  { ado_cursortype => 'adOpenStatic' }
);
ok( defined $sth,"Prepared select * statement, cursortype defined");
ok( $sth->execute,"Execute select");
$sth->finish; $sth = undef;

$sth = $dbh->prepare("SELECT * FROM $tbl",
  { ado_cursortype => 'adOpenStatic' }
);
ok( defined $sth,"Prepared select * statement, cursortype defined");
ok( $sth->execute,"Execute select");
$sth->finish; $sth = undef;

$sth = $dbh->prepare("SELECT * FROM $tbl",
  {
    ado_cursortype => 'adOpenStatic'
  , ado_users      => 1
  }
);
ok( defined $sth,"Prepared select * statement, cursortype and users defined");
ok( $sth->execute,"Execute select");
$sth->finish; $sth = undef;

$sth = $dbh->prepare("SELECT * FROM $tbl",
  {
    ado_cursortype => 'adOpenStatic'
  , ado_usecmd     => 1
  }
);
ok( defined $sth, "Prepared select * statement, cursortype and usecmd defined");
ok( $sth->execute, "Execute select");
$sth->finish; $sth = undef;

$sth = $dbh->prepare("SELECT * FROM $tbl",
  {
    ado_cursortype => 'adOpenStatic'
  , ado_usecmd     => 1
  , ado_users      => 1
  }
);
ok( defined $sth,"Prepared select * statement, cursortype, users, and usecmd defined");
ok( $sth->execute,"Execute select");
$sth->finish; $sth = undef;

# for my $ac ( 0, 1 ) {
#   pass("Testing with AutoCommit $ac");
#   $dbh->{AutoCommit} = $ac;
#
#   # Time how long it takes to run the insert test.
#   my $t_beg = [gettimeofday];
#   run_insert_test( $dbh );
#
#   my $elapsed = tv_interval( $t_beg, [gettimeofday] );
#
#   pass("Run insert test: MAX_ROWS elapsed: $elapsed");
#
#   ok( $dbh->do("DROP TABLE $tbl"),"Drop table $tbl");
# }

# Time how long it takes to run the insert test.
$dbh->{AutoCommit} = 0;
my $t_beg = [gettimeofday];
run_insert_test( $dbh, $tbl );

my $elapsed = tv_interval( $t_beg, [gettimeofday] );

pass("Run insert test: MAX_ROWS elapsed: $elapsed");

for my $i ( 1, 10, 100, 1000 ) {
  my $sth = $dbh->prepare("SELECT * FROM $tbl", { RowCacheSize => $i, ado_users => 1 } );
  ok( defined $sth,"Prepared select * statement, with RowCacheSize and ado_users");

  my $rc = $sth->execute;
  ok( defined $rc,"Execute returned $rc");

  my $t_beg = [gettimeofday];
  while( my $row = $sth->fetch ) {
    $row = undef;
  }
  my $elapsed = tv_interval( $t_beg, [gettimeofday] );
  pass("Run select all test: cache: $i Max rows: MAX_ROWS elapsed: $elapsed");
}

$dbh->{AutoCommit} = 1;

ok( $dbh->do("DROP TABLE $tbl"),"Drop table $tbl");

ok( $dbh->disconnect,'Disconnect');


sub run_insert_test {
  my $dbh = shift;
  my $tbl = shift;

  my $sth = $dbh->prepare("INSERT INTO $tbl( B ) VALUES( ? )", { ado_usecmd => 1 } );
  ok( defined $sth,'Insert statement prepared');
  ok( !$dbh->err,'No error on prepare.');

  pass("Loading rows into table: $tbl");

  my $cnt = 0; my $added = 0;
  my $ac = $dbh->{AutoCommit};
  while( $cnt < $MAX_ROWS ) {
    $added += ($sth->execute("Just a text message for $cnt") || 0 );
  } continue {
    $cnt++;
    $dbh->commit if $ac == 0 && $cnt % 1000 == 0;
    print "# Checkpoint: $cnt\n" if $cnt % 1000 == 0;
  }
  $dbh->commit if $ac == 0;

  ok( $added > 0,"Added $added rows to test using count of $cnt");
  ok( $added == $MAX_ROWS,"Added MAX $MAX_ROWS rows to test using count of $cnt");

  $sth->finish; $sth = undef;
  return;
}
