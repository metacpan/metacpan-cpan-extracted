#!/usr/local/bin/perl -w

# $Id: test.pl,v 1.24 1999/09/29 20:30:23 mergl Exp $

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### not tested explicitly
#
# AutoCommit
# commit
# rollback
# Active
# Statement
# attributes
# err
# pg_auto_escape
# quote
# type_info_all
#
######################### We start with some black magic to print on failure.

BEGIN { $| = 1; }
END {print "test failed\n" unless $loaded;}
use DBI;
$loaded = 1;
use Config;
use strict;

######################### End of black magic.

my $os = $^O;
print "OS: $os\n";

my $dbmain = "template1";
my $dbtest = "pgperltest";

# optionally add ";host=$remotehost port=remoteport"
my $dsn_main = "dbi:Pg:dbname=$dbmain";
my $dsn_test = "dbi:Pg:dbname=$dbtest";

my ($dbh0, $dbh, $sth);

#DBI->trace(3); # make your choice

######################### drop, create and connect to test database

( $dbh0 = DBI->connect("$dsn_main", "", "") )
    and print "DBI->connect ............... ok\n"
    or  die   "DBI->connect ............... not ok: ", $DBI::errstr;

$dbh0->{PrintError} = 0; # do not complain when dropping $dbtest
$dbh0->do("DROP DATABASE $dbtest");

( $dbh0->do("CREATE DATABASE $dbtest") )
    and print "\$dbh->do ................... ok\n"
    or  die   "\$dbh->do ................... not ok: ", $DBI::errstr;

$dbh = DBI->connect("$dsn_test", "", "") or die $DBI::errstr;

# now, the rest of the script is loaded as a big stored procedure, and
# executed. This is gonna be fun. 

my $sp;
while(<DATA>)  { $sp.=$_; }

my $esc_sp=$dbh->quote($sp);

$dbh->{RaiseError}=1;
$dbh->do("CREATE OR REPLACE FUNCTION dbd_spi_test() returns text as $esc_sp language 'plperlu'");
$dbh->do("select dbd_spi_test()");


exit;
=secret
######################### test large objects

# create large object from binary file

my ($ascii, $pgin);
foreach $ascii (0..255) {
    $pgin .= chr($ascii);
};

my $PGIN = '/tmp/pgin';
open(PGIN, ">$PGIN") or die "can not open $PGIN";
print PGIN $pgin;
close PGIN;

# begin transaction
$dbh->{AutoCommit} = 0;

my $lobjId;
( $lobjId = $dbh->func($PGIN, 'lo_import') )
    and print "\$dbh->func(lo_import) ...... ok\n"
    or  print "\$dbh->func(lo_import) ...... not ok\n";

# end transaction
$dbh->{AutoCommit} = 1;

unlink $PGIN;


# blob_read

# begin transaction
$dbh->{AutoCommit} = 0;

$sth = $dbh->prepare( "" ) or die $DBI::errstr;

my $blob;
( $blob = $sth->blob_read($lobjId, 0, 0) )
    and print "\$sth->blob_read ............ ok\n"
    or  print "\$sth->blob_read ............ not ok\n";

$sth->finish or die $DBI::errstr;

# end transaction
$dbh->{AutoCommit} = 1;


# read large object using lo-functions

# begin transaction
$dbh->{AutoCommit} = 0;

my $lobj_fd; # may be 0
( defined($lobj_fd = $dbh->func($lobjId, $dbh->{pg_INV_READ}, 'lo_open')) )
    and print "\$dbh->func(lo_open) ........ ok\n"
    or  print "\$dbh->func(lo_open) ........ not ok\n";

( 0 == $dbh->func($lobj_fd, 0, 0, 'lo_lseek') )
    and print "\$dbh->func(lo_lseek) ....... ok\n"
    or  print "\$dbh->func(lo_lseek) ....... not ok\n";

my $buf = '';
( 256 == $dbh->func($lobj_fd, $buf, 256, 'lo_read') )
    and print "\$dbh->func(lo_read) ........ ok\n"
    or  print "\$dbh->func(lo_read) ........ not ok\n";

( 256 == $dbh->func($lobj_fd, 'lo_tell') )
    and print "\$dbh->func(lo_tell) ........ ok\n"
    or  print "\$dbh->func(lo_tell) ........ not ok\n";

( $dbh->func($lobj_fd, 'lo_close') )
    and print "\$dbh->func(lo_close) ....... ok\n"
    or  print "\$dbh->func(lo_close) ....... not ok\n";

( $dbh->func($lobjId, 'lo_unlink') )
    and print "\$dbh->func(lo_unlink) ...... ok\n"
    or  print "\$dbh->func(lo_unlink) ...... not ok\n";

# end transaction
$dbh->{AutoCommit} = 1;


# compare large objects

( $pgin cmp $buf and $pgin cmp $blob )
    and print "compare blobs .............. not ok\n"
    or  print "compare blobs .............. ok\n";

######################### disconnect and drop test database

# disconnect

( $dbh->disconnect )
    and print "\$dbh->disconnect ........... ok\n"
    or  die   "\$dbh->disconnect ........... not ok: ", $DBI::errstr;

$dbh0->do("DROP DATABASE $dbtest");
$dbh0->disconnect;

print "test sequence finished.\n";

######################### EOF
# the actual test script is here
=cut
__DATA__
use DBD::PgSPI;
use Data::Dumper;

$pg_dbh->{RaiseError}=1;

$pg_dbh->do("CREATE TABLE builtin ( 
  bool_      bool,
  char_      char,
  char12_    char(12),
  char16_    char(16),
  varchar12_ varchar(12),
  text_      text,
  date_      date,
  int4_      int4,
  int4a_     int4[],
  float8_    float8,
  point_     point,
  lseg_      lseg,
  box_       box
  )");

#sleep 15;

my $sth = $pg_dbh->table_info('','','builtin','');
my @infos = $sth->fetchrow_array;
$sth->finish;

( join(" ", @infos[2,3]) eq q{builtin TABLE} ) 
    and print STDERR "\$pg_dbh->table_info ........... ok\n"
    or  print STDERR "\$pg_dbh->table_info ........... not ok: ", join(" ", @infos), "\n";

#my @names = $pg_dbh->tables;
#( join(" ", @names) eq q{builtin} ) 
#    and print STDERR "\$pg_dbh->tables ............... ok\n"
#    or  print "\$pg_dbh->tables ............... not ok: ", join(" ", @names), "\n";

#my $attrs = $pg_dbh->func('builtin', 'table_attributes');
#(  $$attrs[0]{NAME} eq q{varchar12_} ) 
#    and print STDERR "\$pg_dbh->pg_table_attributes .. ok\n"
#    or  print STDERR "\$pg_dbh->pg_table_attributes .. not ok: ", $$attrs[0]{NAME}, "\n";
#
######################### test various insert methods

# insert into table with $dbh->do($stmt)

$pg_dbh->do("INSERT INTO builtin VALUES(
  't',
  'a',
  'Edmund Mergl',
  'quote \\\\ '' this',
  'Edmund Mergl',
  'Edmund Mergl',
  '08-03-1997',
  1234,
  '{1,2,3}',
  1.234,
  '(1.0,2.0)',
  '((1.0,2.0),(3.0,4.0))',
  '((1.0,2.0),(3.0,4.0))'
  )") or die $DBI::errstr;


# insert into table with $dbh->prepare() with placeholders and $dbh->execute(@bind_values)

( $sth = $pg_dbh->prepare( "INSERT INTO builtin 
  ( bool_, char_, char12_, char16_, varchar12_, text_, date_, int4_, int4a_, float8_, point_, lseg_, box_ )
  VALUES ( ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ? )
  " ) )
    and print STDERR "\$pg_dbh->prepare .............. ok\n"
    or  die   "\$pg_dbh->prepare .............. not ok: ", $DBI::errstr;

( $sth->execute (
  'f',
  'b',
  'Halli  Hallo',
  'but  not  \164\150\151\163',
  'Halli  Hallo',
  'Halli  Hallo',
  '06-01-1995',
  5678,
  '{5,6,7}',
  5.678,
  '(4.0,5.0)',
  '((4.0,5.0),(6.0,7.0))',
  '((4.0,5.0),(6.0,7.0))'
  ) )
    and print STDERR "\$pg_dbh->execute .............. ok\n"
    or  die   "\$pg_dbh->execute .............. not ok: ", $DBI::errstr;

$sth->execute (
  'f',
  'c',
  'Potz   Blitz',
  'Potz   Blitz',
  'Potz   Blitz',
  'Potz   Blitz',
  '05-10-1957',
  1357,
  '{1,3,5}',
  1.357,
  '(2.0,7.0)',
  '((2.0,7.0),(8.0,3.0))',
  '((2.0,7.0),(8.0,3.0))'
   ) or die $DBI::errstr;

# insert into table with $pg_dbh->do($stmt, @bind_values)

$pg_dbh->do( "INSERT INTO builtin 
  VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ? )",
   {},
   'y',
   'z',
   'Ene Mene  Mu',
   'Ene Mene  Mu',
   'Ene Mene  Mu',
   'Ene Mene  Mu',
   '10-10-1957',
   5432,
   '{6,7,8}',
   6.789,
   '(5.0,6.0)',
   '((5.0,6.0),(7.0,8.0))',
   '((5.0,6.0),(7.0,8.0))'
   ) or die $DBI::errstr;

my $pg_oid_status = $sth->{pg_oid_status};
( $pg_oid_status ne '' )
    and print STDERR "\$sth->{pg_oid_status} ...... ok\n"
    or  print STDERR "\$sth->{pg_oid_status} ...... not ok: $pg_oid_status\n";


my $pg_cmd_status = $sth->{pg_cmd_status};
( $pg_cmd_status =~ /^INSERT/ )
    and print STDERR "\$sth->{pg_cmd_status} ...... ok\n"
    or  print STDERR "\$sth->{pg_cmd_status} ...... not ok: $pg_cmd_status\n";

( $sth->finish )
    and print STDERR "\$sth->finish ............... ok\n"
    or  die   "\$sth->finish ............... not ok: ", $DBI::errstr;

######################### test various select methods

# select from table using input parameters and and various fetchrow methods

$sth = $pg_dbh->prepare("SELECT * FROM builtin where int4_ < ? + ?") or die $DBI::errstr;

( $sth->bind_param(1, '4000', DBI::SQL_INTEGER) )
    and print STDERR "\$sth->bind_param ........... ok\n"
    or  die   "\$sth->bind_param ........... not ok: ", $DBI::errstr;
$sth->bind_param(2, '6000', DBI::SQL_INTEGER);

$sth->execute or die $DBI::errstr;

my @row_ary = $sth->fetchrow_array;
( join(" ", @row_ary) eq q{1 a Edmund Mergl quote \ ' this   Edmund Mergl Edmund Mergl 1997-08-03 1234 {1,2,3} 1.234 (1,2) [(1,2),(3,4)] (3,4),(1,2)} ) 
    and print STDERR "\$sth->fetchrow_array ....... ok\n"
    or  print STDERR "\$sth->fetchrow_array ....... not ok: ", join(" ", @row_ary), "\n";

my $ary_ref = $sth->fetchrow_arrayref;
( join(" ", @$ary_ref) eq q{0 b Halli  Hallo but  not  this   Halli  Hallo Halli  Hallo 1995-06-01 5678 {5,6,7} 5.678 (4,5) [(4,5),(6,7)] (6,7),(4,5)} )
    and print STDERR "\$sth->fetchrow_arrayref .... ok\n"
    or  print STDERR "\$sth->fetchrow_arrayref .... not ok: ", join(" ", @$ary_ref), "\n";

# xxx: broken because depends on specific hash ordering
#my ($key, $val);
#my $hash_ref = $sth->fetchrow_hashref;
#( join(" ", (($key,$val) = each %$hash_ref)) eq q{char12_ Potz   Blitz} )
#    and print STDERR "\$sth->fetchrow_hashref ..... ok\n"
#    or  print STDERR "\$sth->fetchrow_hashref ..... not ok:  key = $key, val = $val\n";
#
# test various attributes
my @name = @{$sth->{NAME}};
( join(" ", @name) eq q{bool_ char_ char12_ char16_ varchar12_ text_ date_ int4_ int4a_ float8_ point_ lseg_ box_} )
    and print STDERR "\$sth->{NAME} ............... ok\n"
    or  print STDERR "\$sth->{NAME} ............... not ok: ", join(" ", @name), "\n";

my @type = @{$sth->{TYPE}};
( join(" ", @type) eq q{16 1042 1042 1042 1043 25 1082 23 1007 701 600 601 603} )
    and print STDERR "\$sth->{TYPE} ............... ok\n"
    or  print STDERR "\$sth->{TYPE} ............... not ok: ", join(" ", @type), "\n";

my @pg_size = @{$sth->{pg_size}};
( join(" ", @pg_size) eq q{1 -1 -1 -1 -1 -1 4 4 -1 8 16 32 32} )
    and print STDERR "\$sth->{pg_size} ............ ok\n"
    or  print STDERR "\$sth->{pg_size} ............ not ok: ", join(" ", @pg_size), "\n";

my @pg_type = @{$sth->{pg_type}};
( join(" ", @pg_type) eq q{bool bpchar bpchar bpchar varchar text date int4 _int4 float8 point lseg box} )
    and print STDERR "\$sth->{pg_type} ............ ok\n"
    or  print STDERR "\$sth->{pg_type} ............ not ok: ", join(" ", @pg_type), "\n";

# test binding of output columns

$sth->execute or die $DBI::errstr;

my ($bool, $char, $char12, $char16, $vchar12, $text, $date, $int4, $int4a, $float8, $point, $lseg, $box);
( $sth->bind_columns(undef, \$bool, \$char, \$char12, \$char16, \$vchar12, \$text, \$date, \$int4, \$int4a, \$float8, \$point, \$lseg, \$box) )
    and print STDERR "\$sth->bind_columns ......... ok\n"
    or  print STDERR "\$sth->bind_columns ......... not ok: ", $DBI::errstr;

$sth->fetch or die $DBI::errstr;
( "$bool, $char, $char12, $char16, $vchar12, $text, $date, $int4, $int4a, $float8, $point, $lseg, $box" eq 
  q{1, a, Edmund Mergl, quote \ ' this  , Edmund Mergl, Edmund Mergl, 1997-08-03, 1234, {1,2,3}, 1.234, (1,2), [(1,2),(3,4)], (3,4),(1,2)} )
    and print STDERR "\$sth->fetch ................ ok\n"
    or  print STDERR "\$sth->fetch ................ not ok:  $bool, $char, $char12, $char16, $vchar12, $text, $date, $int4, $int4a, $float8, $point, $lseg, $box\n";

my $gaga;
( $sth->bind_col(5, \$gaga) )
    and print STDERR "\$sth->bind_col ............. ok\n"
    or  print STDERR "\$sth->bind_col ............. not ok: ", $DBI::errstr;

$sth->fetch or die $DBI::errstr;
( $gaga eq q{Halli  Hallo} )
    and print STDERR "\$sth->fetch ................ ok\n"
    or  print STDERR "\$sth->fetch ................ not ok: $gaga\n";

$sth->finish or die $DBI::errstr;

# select from table using input parameters

$sth = $pg_dbh->prepare( "SELECT * FROM builtin where char16_ = ?" ) or die $DBI::errstr;

my $string = q{quote \ ' this};
$sth->bind_param(1, $string) or die $DBI::errstr;

# $pg_dbh->{pg_auto_escape} = 1;
# is needed for $string above and is on by default
$sth->execute or die $DBI::errstr;

$sth->{ChopBlanks} = 1;
@row_ary = $sth->fetchrow_array;
                           1 a Edmund Mergl quote \ ' this   Edmund Mergl Edmund Mergl 1997-08-03 1234 {1,2,3} 1.234 (1,2) [(1,2),(3,4)] (3,4),(1,2)
( join(" ", @row_ary) eq q{1 a Edmund Mergl quote \ ' this Edmund Mergl Edmund Mergl 1997-08-03 1234 {1,2,3} 1.234 (1,2) [(1,2),(3,4)] (3,4),(1,2)} ) 
    and print STDERR "\$sth->{ChopBlanks} ......... ok\n"
    or  print STDERR "\$sth->{ChopBlanks} .......... not ok: ", join(" ", @row_ary), "\n";

my $rows = $sth->rows;
( 1 == $rows )
    and print STDERR "\$sth->rows ................. ok\n"
    or  print STDERR "\$sth->rows ................. not ok: $rows\n";

$sth->finish or die $DBI::errstr;


