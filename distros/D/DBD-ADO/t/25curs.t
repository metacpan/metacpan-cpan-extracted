#!perl -I./t

$| = 1;

use strict;
use warnings;
use DBI();
use DBD_TEST();

use Test::More;

if (defined $ENV{DBI_DSN}) {
  plan tests => 32;
} else {
  plan skip_all => 'Cannot test without DB info';
}

pass('Cursor type tests');

my $tbl = $DBD_TEST::table_name;
my @col = sort keys %DBD_TEST::TestFieldInfo;

my $non_supported = '-2146825037';

my $longstr = 'THIS IS A STRING LONGER THAN 80 CHARS.  THIS SHOULD BE CHECKED FOR TRUNCATION AND COMPARED WITH ITSELF.';
my $longstr2 = $longstr . '  ' . $longstr . '  ' . $longstr . '  ' . $longstr;

my $data =
[
  [ 3,'bletch'   ,'bletch varchar','1998-05-10 00:00:00']
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

my ( $sth1, $sth2 );
pass('Test creating two statement handles. Execute in series.');
ok( $sth1 = $dbh->prepare("SELECT * FROM $tbl ORDER BY A"),'Prepare statement handle 1');
ok( $sth2 = $dbh->prepare("SELECT * FROM $tbl ORDER BY A"),'Prepare statement handle 2');

ok( defined $sth1,'Statement handle 1 defined');
ok( defined $sth2,'Statement handle 2 defined');
{
  ok( $sth1->execute,'Execute statement handle 1');
  my $cnt = 0;
  while ( my $row = $sth1->fetch ) {
    $cnt++;
#   print "#\t", DBI::neat_list( $row ), "\n";
  }
  ok( $cnt > 0,"Rows fetched: $cnt > 0");
}
{
  ok( $sth2->execute,'Execute statement handle 2');
  my $cnt = 0;
  while ( my $row = $sth2->fetch ) {
    $cnt++;
#   print "#\t", DBI::neat_list( $row ), "\n";
  }
  ok( $cnt > 0,"Rows fetched: $cnt > 0");
}
undef $sth1;
undef $sth2;

# Testing a prepare statement with different cursor types.

my @CursorTypes = qw(adOpenForwardOnly adOpenKeyset adOpenDynamic adOpenStatic);
for my $ct ( @CursorTypes ) {
  my $sth = $dbh->prepare("SELECT * FROM $tbl ORDER BY A", { ado_cursortype => $ct } );
  ok( $sth,"Prepare statement handle using CursorType => $ct");
  my $rc = $sth->execute;
  SKIP: {
    skip("CusorType: $ct, not supported by Provider", 2 )
      if defined $sth->err && $sth->err eq $non_supported;
    ok( $rc,"Execute statement handle using CursorType => $ct : $rc");

    my $cnt = 0;
    while ( my $row = $sth->fetch ) {
      $cnt++;
#     print "#\t", DBI::neat_list( $row ), "\n";
    }
    ok( $cnt > 0,"Rows fetched: $cnt > 0        for CursorType => $ct");
  }
  ok( $sth->finish,"Finish  statement handle using CursorType => $ct");
}

# MS SQL test.
# {
#   local ($dbh->{AutoCommit});
#   $dbh->{AutoCommit} = 0;
#   $dbh->rollback;
#
# pass( "Test creating executing statement handle 2 while looping statement handle 1" );
# ok ( $sth1 = $dbh->prepare( q{select name, type from sysobjects where type = 'U '},
#   { ado_cursortype => 'adOpenStatic' } ),
#   " test prepare with CursorType => adOpenStatic");
#
# die "Undefined statement handle: \n" unless $sth1;
#
# $sth1->execute;
# # print join("\n#\t", @{$sth1->{NAME}} ), "\n";
# while( my ($name, $type) = $sth1->fetchrow_array ) {
# #   print "# Object $name, Type $type\n";
#   my $sth2;
#   ok( $sth2 = $dbh->prepare("select * from $name", { ado_cursortype => 'adOpenForwardOnly' } ),
#     " selecting data from $name CursorType => adOpenForwardOnly"
#   );
#
#   ok(!$sth2->execute, " execute second handle CursorType => adOpenForwardOnly" );
#   my $row;
#   $row = $sth2->fetchrow;
#   ok(!$sth2->err, " fetchrow: " . defined $sth2->err ? $sth2->errstr : 'no errors' );
# #   print "# Table: $name: Columns: \n", join( "\n\t", @{$sth2->{NAME}}), "\n";
#   ok( $sth2->finish, " finished second handle" );
# }
#
# $sth1->finish;
#
# }

ok( DBD_TEST::tab_delete( $dbh ),'Drop test table');

ok( $dbh->disconnect,'Disconnect');


sub tab_select  # similar to 02simple.t
{
  my $dbh = shift;
  my $rowcount = 0;

  my $sth = $dbh->prepare("SELECT * FROM $tbl ORDER BY A") or return undef;
  $sth->execute;
  while ( my $row = $sth->fetch )  {
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
