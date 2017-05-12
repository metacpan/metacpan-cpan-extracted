#!perl -I./t

$| = 1;

use strict;
use warnings;
use DBI();
use DBD_TEST();

use Test::More;

if ( defined $ENV{DBI_DSN} ) {
  plan tests => 22;
} else {
  plan skip_all => 'Cannot test without DB info';
}

pass('Miscellaneous tests');

my $tbl = $DBD_TEST::table_name;
my @col = sort keys %DBD_TEST::TestFieldInfo;

my $longstr = 'THIS IS A STRING LONGER THAN 80 CHARS.  THIS SHOULD BE CHECKED FOR TRUNCATION AND COMPARED WITH ITSELF.';
my $longstr2 = $longstr . '  ' . $longstr . '  ' . $longstr . '  ' . $longstr;

my $data =
[
  [ 3,'bletch'   ,'bletch varchar','1998-05-10']
, [ 1,'foo'      ,'foo varchar'   ,'1998-05-11']
, [ 2,'bar'      ,'bar varchar'   ,'1998-05-12']
, [ 4,'80char'   , $longstr       ,'1998-05-13']
, [ 5,'gt250char', $longstr2      ,'1998-05-14']
];


my $dbh = DBI->connect or die "Connect failed: $DBI::errstr\n";
  $dbh->{RaiseError} = 1;
  $dbh->{PrintError} = 0;
pass('Database connection created');

ok( DBD_TEST::tab_create( $dbh ),"CREATE TABLE $tbl");

ok( tab_insert( $dbh, $data, \@col ),'Insert test data');
ok( tab_select( $dbh ),'Select test data');

$dbh->{LongReadLen} = 50;
$dbh->{LongTruncOk} = 1;
is( select_long( $dbh ), 1, 'Test LongTruncOk ON');

$dbh->{LongTruncOk} = 0;
is( select_long( $dbh ), 0, 'Test LongTruncOk OFF');

#
# some ADO drivers will prepare this OK, but not execute.
#
{
  # Turn the warnings off at this point.  Expecting statement to fail.
  local ( $dbh->{Warn}, $dbh->{RaiseError}, $dbh->{PrintError} );
  $dbh->{RaiseError} = $dbh->{PrintError} = $dbh->{Warn} = 0;

  my $sth = $dbh->prepare("SELECT XXNOTCOLUMN FROM $tbl");
  $sth->execute if $sth;
  ok( $sth->err,'Check error returned, statement handle');
  ok( $dbh->err,'Check error returned, database handle');
  ok( $DBI::err,'Check error returned, DBI::err');
}

my $sth = $dbh->prepare("SELECT D FROM $tbl WHERE D > ?");
my $ti = DBD_TEST::get_type_for_column( $dbh,'D');
my $dt = '1998-05-12';
$sth->bind_param( 1, $dt, { TYPE => $ti->{DATA_TYPE} } );
$sth->execute;
my $count = 0;
while ( my $row = $sth->fetch ) {
  $count++ if $row->[0];
  # print "$row->[0]\n";
}
is( $count, 2,"Test date value: $dt, count: $count");

$sth = $dbh->prepare("SELECT A, COUNT(*) FROM $tbl GROUP BY A");
$sth->execute;
$count = 0;
while ( my $row = $sth->fetch ) {
  $count++ if $row->[0];
  # print "$row->[0], $row->[1]\n";
}
ok( $count,"Test group by queries, count: $count");


my $sth1 = $dbh->prepare("SELECT * FROM $tbl ORDER BY A") or warn $dbh->errstr;
my $sth2 = $dbh->prepare("SELECT * FROM $tbl ORDER BY A") or warn $dbh->errstr;
ok( defined $sth1,'Statement handle 1 created');
ok( defined $sth2,'Statement handle 2 created');

$sth1 = undef; $sth2 = undef; $sth = undef;

$count = 0;
$sth1 = $dbh->prepare("SELECT * FROM $tbl where A = ?") or warn $dbh->errstr;
ok( defined $sth1,'Prepared statement * and Parameter');

{
  # Turn PrintError and RaiseError off
  local ( $dbh->{PrintError}, $dbh->{RaiseError} );
  $dbh->{PrintError} = 0; $dbh->{RaiseError} = 0;
  $sth1 = $dbh->prepare("SELECT Z FROM $tbl where A = ?") or warn $dbh->errstr;
  ok( defined $sth1,'Prepared statement bad column and Parameter');

  my @row = $sth1->fetchrow;
  ok( $sth1->err,'Call to fetchrow w/o execute: ' . $sth1->errstr );
  is( scalar @row, 0,'@row should be empty: ' . scalar @row );
}

{
  $sth1 = $dbh->prepare("SELECT * FROM $tbl where A = ?") or warn $dbh->errstr;
  ok( defined $sth1,'Prepared statement * and Parameter');

  $sth1 = $dbh->prepare("SELECT Z FROM $tbl where A = ?") or warn $dbh->errstr;
  ok( defined $sth1,'Prepared statement bad column and Parameter');

  eval {
    local ( $sth1->{PrintError}, $sth1->{RaiseError} );
    $sth1->{PrintError} = 0; $sth1->{RaiseError} = 1;
    $sth1->execute( 99 );
    my @row = $sth1->fetchrow;
  };
  ok( defined $@,"RaiseError caught error:\n$@");
}

ok( $dbh->disconnect,'Disconnect');


sub tab_select
{
  my $dbh = shift;
  my $rowcount = 0;

  my $sth = $dbh->prepare("SELECT * FROM $tbl ORDER BY A") or return undef;
  $sth->execute;
  while ( my $row = $sth->fetch ) {
    print "# -- $row->[0] $row->[1] $row->[2] $row->[3]\n";
    ++$rowcount;
  }
  if ( $rowcount == 0 ) {
    print "# -- Basic retrieval of rows not working!\n";
    return 0;
  }

  $sth = $dbh->prepare("SELECT A, C FROM $tbl WHERE A >= 4") or return undef;
  $rowcount = 0;
  $sth->execute;
  while ( my $row = $sth->fetch ) {
    $rowcount++;
    if ( $row->[0] == 4 ) {
      if ( $row->[1] eq $longstr ) {
        print '# -- Retrieved ', length( $longstr ), " byte string OK\n";
      } else {
        print "# -- Basic retrieval of longer rows not working!\n-- Retrieved value = $row->[0]\n";
        return 0;
      }
    } elsif ( $row->[0] == 5 ) {
      if ( $row->[1] eq $longstr2 ) {
        print '# -- Retrieved ', length( $longstr2 ), " byte string OK\n";
      } else {
        print "# -- Basic retrieval of row longer than 255 chars not working!",
            "\n# -- Retrieved ", length( $row->[1] ), ' bytes instead of ',
            length( $longstr2 ), "\n-- Retrieved value = $row->[1]\n";
        return 0;
      }
    }
  }
  if ( $rowcount == 0 ) {
    print "# -- Basic retrieval of rows not working!\n-- Rowcount = $rowcount\n";
    return 0;
  }
  return 1;
}

sub tab_insert {
  my $dbh  = shift;
  my $data = shift;
  my $cols = shift;

  my $sth = $dbh->prepare("INSERT INTO $tbl( A, B, C, D ) VALUES( ?, ?, ?, ? )");

  for ( @$data ) {
    for my $i ( 0..$#$cols ) {
      my $ti = DBD_TEST::get_type_for_column( $dbh, $cols->[$i] );
      $sth->bind_param( $i+1, $_->[$i], { TYPE => $ti->{DATA_TYPE} } );
    }
    $sth->execute;
  }
  return 1;
}

sub select_long
{
  my $dbh = shift;
  my $rc = 0;

  local $dbh->{RaiseError} = 1;
  local $dbh->{PrintError} = 0;
  my $sth = $dbh->prepare("SELECT A,C FROM $tbl WHERE A=4");
  if ( $sth ) {
    $sth->execute;
    eval {
      while ( my $row = $sth->fetch ) {
      }
    };
    $rc = 1 unless $@;
  }
  $rc;
}
