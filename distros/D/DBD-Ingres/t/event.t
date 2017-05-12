#                              -*- Mode: Perl -*- 
# $Basename$
# $Revision: 1.2 $
# Author          : Ulrich Pfeifer
# Created On      : Mon Sep 22 09:07:49 1997
# Last Modified By: Ulrich Pfeifer
# Last Modified On: Mon Sep 22 11:36:03 1997
# Language        : CPerl
# 

use DBI qw(:sql_types);
$verbose   = 1;
$testtable = "testhththt";

$dbname = $ENV{DBI_DBNAME} || $ENV{DBI_DSN} ||
           &ask_user("Please enter database-name: ");
$dbname = "dbi:Ingres:$dbname" unless $dbname =~ /^dbi:Ingres/;
print "1..17\n";
my $test = 0;

$test++;
print "Testing: DBI->connect('$dbname'):\n"
 	if $verbose;
( $dbh = DBI->connect($dbname) )
    and print("ok $test\n") 
    or die "not ok $test: $DBI::errstr\n";
$dbh->{AutoCommit} = 0;

sub run_test ($ ) {
  my $cmd = shift;

  $test++;
  print "Testing: \$dbh->do( '$cmd' ):\n"
    if $verbose;
  ( $dbh->do( $cmd ) )
    and print( "ok $test\n" )
      or print "not ok $test: $DBI::errstr\n";
}

sub run_test_prepare ($ ) {
  my $cmd = shift;
  my $cursor;
  
  $test++;
  print "Testing: $cursor = \$dbh->prepare( '$cmd' ):\n"
    if $verbose;
  ( $cursor = $dbh->prepare( $cmd ) )
    and print( "ok $test\n" )
      or print "not ok $test: $DBI::errstr\n";

  $test++;
  print "Testing: $cursor \$cursor->execute:\n"
	if $verbose;
  ( $cursor and $cursor->execute )
    and print( "ok $test\n" )
      or print "not ok $test: $DBI::errstr\n";
}

run_test qq[
           CREATE TABLE $testtable
                       (
                        id INTEGER4,
                        name CHAR(64)
                       )
           ];

run_test q[
           CREATE DBEVENT people_update
          ];

run_test q[
           CREATE PROCEDURE signal_people ( the_id integer4 not NULL ) AS
           DECLARE text VARCHAR(10) not NULL;
           BEGIN
           text = varchar(the_id);
           RAISE DBEVENT people_update text ;
           END
          ];

run_test qq[
            CREATE RULE people_change
            AFTER INSERT OF $testtable
            EXECUTE PROCEDURE signal_people (the_id = $testtable.id)
          ];
run_test q[
           REGISTER DBEVENT people_update
          ];
run_test qq[
            INSERT INTO $testtable VALUES ( 1, 'Alligator Descartes' )
           ];

$test++;
print "Committing\n"
	if $verbose;
( $dbh->commit )
   and print "ok $test\n"
   or print "not ok $test: $DBI::errstr\n";

$test++;
print "Testing \$dbh->func(10, 'get_dbevent')\n"
	if $verbose;
( $event = $dbh->func(10, 'get_dbevent') )
   and print "ok $test\n"
   or print "not ok $test: $DBI::errstr\n";

for (keys %$event) {
  printf "%-20s = '%s'\n", $_, $event->{$_};
}

run_test qq[
            INSERT INTO $testtable VALUES ( 2, 'Ulrich Pfeifer' )
           ];

$test++;
print "Testing \$dbh->func('get_dbevent')\n"
	if $verbose;
( $event = $dbh->func('get_dbevent') )
   and print "ok $test\n"
   or print "not ok $test: $DBI::errstr\n";

for (keys %$event) {
  printf "%-20s = '%s'\n", $_, $event->{$_};
}

# This one should time out
$test++;
print "Testing \$dbh->func(10, 'get_dbevent')\nThis one should time out after 10 seconds\n"
	if $verbose;
( $event = $dbh->func(10,'get_dbevent') )
   and print "not ok $test\n"
   or print "ok $test\n";

run_test qq[
            DROP DBEVENT people_update
           ];
run_test qq[
            DROP RULE people_change
           ];
run_test qq[
            DROP PROCEDURE signal_people
           ];
run_test qq[
            DROP TABLE $testtable
           ];

$test++;
print "Committing\n"
	if $verbose;
( $dbh->commit )
   and print "ok $test\n"
   or print "not ok $test: $DBI::errstr\n";
print "*** Testing of DBD::Ingres complete! You appear to be normal! ***\n"
	if $verbose;

sub ask_user {
    # gets information from the user
    my $ans;
    print @_;
    $ans = <>;
    $ans;
}
