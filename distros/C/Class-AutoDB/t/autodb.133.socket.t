# Regression test: socket bug in _connect. was using wrong property name when 
# setting 'socket' in dsn. was 'sock'; should be 'mysql_socket'
# Also first attempt to use Test::mysqld
use t::lib;
use Carp;
use DBI;
use File::Spec;
use List::MoreUtils qw(all);
use List::Util qw(first);
use Test::Deep qw(cmp_details bag);
use Test::More;
use DBI;
use Class::AutoDB;
use autodbUtil;
use strict;

my $errstr;			# global variable set in tests

SKIP: {
  # Ensure a recent version of Test::mysqld
  my $min_version=0.17;
  eval "use Test::mysqld $min_version";
  skip "socket test: Test::mysqld $min_version required",1 if $@;

  # first test with 'naked' DBI connect
  my $dsn='DBI:mysql:dbname='.testdb;
  # note("testing dbh from DBI connect dsn=$dsn");
  my $dbh=DBI->connect($dsn);
  report_fail($dbh,"DBI connect dsn=$dsn") or goto QUIT;
  check_mysql($dbh,testdb) or goto QUIT;
  pass("dbh from DBI connect dsn=$dsn");

  # now test with AutoDB created the usual way
  my $autodb=new Class::AutoDB(database=>testdb,create=>1);
  report_fail($autodb,"AutoDB created the usual way") or goto QUIT;
  # note("testing dbh from AutoDB created the usual way");
  check_mysql($dbh,testdb) or goto QUIT;
  pass("dbh from AutoDB created the usual way");

  # now test with AutoDB created using socket
  my $socket=find_socket();
  if ($socket) {
    my $autodb=new Class::AutoDB(socket=>$socket,database=>testdb,create=>1);
    report_fail($autodb,"AutoDB created from socket") or goto QUIT;
    # note('testing dbh from AutoDB created from socket');
    check_mysql($autodb->dbh,testdb) or goto QUIT;
    pass('dbh from AutoDB created from socket');
  }

  # now test with private MySQL instance
  # variables needed for private MySQL instance
  # MYSQL_dir defined in autodbUtil
  # my $MYSQL_dir=File::Spec->catdir(qw(t MYSQL));
  my $etc_dir=File::Spec->catdir($MYSQL_dir,'etc');
  my $tmp_dir=File::Spec->catdir($MYSQL_dir,'tmp');
  my $var_dir=File::Spec->catdir($MYSQL_dir,'var');
  my $pid_file=File::Spec->catfile($tmp_dir,'mysqld.pid');
  my $socket_file=File::Spec->catfile($tmp_dir,'mysql.sock');

  mkdir $MYSQL_dir unless -e $MYSQL_dir;
  report_fail(-d $MYSQL_dir,"create MYSQL directory $MYSQL_dir") or goto QUIT;
  my $mysqld=new Test::mysqld(my_cnf=>{'skip-networking'=>''},base_dir=>$MYSQL_dir,auto_start=>0);
  report_fail($mysqld,'new Test::mysqld');
  # see if we have to setup mysqld
  $mysqld->setup unless all {-d $_} ($etc_dir,$tmp_dir,$var_dir);
  report_fail((all {-d $_} ($etc_dir,$tmp_dir,$var_dir)),
	      "private MySQL setup in directory $MYSQL_dir")  or goto QUIT;
  $mysqld->start;		# start mysqld
  # NG 13-09-04: actually, we want to stop the server else server processes accumulate...
  # $mysqld->pid(undef);		# HACK so DESTROY won't stop server
  # NG 13-10-23: be more cautoius about how we connect to private instance
  #              code adapted from 000.reqs
  my $user=$ENV{USER};
  my $sock=File::Spec->rel2abs($socket_file);
  eval {$dbh=DBI->connect("dbi:mysql:mysql_socket=$sock",$user,undef,
			  {AutoCommit=>1, ChopBlanks=>1, PrintError=>0, PrintWarn=>0, Warn=>0,})};
  unless ($dbh) {
    # try as root
    $user='root';
    eval {$dbh=DBI->connect("dbi:mysql:mysql_socket=$sock",$user,undef,
			    {AutoCommit=>1, ChopBlanks=>1, PrintError=>0, PrintWarn=>0, Warn=>0,})};
    goto QUIT unless $dbh;
  }
  # able to connect, so continue the test. Test::mysqld->start creates test database
  check_mysql($dbh,'test') or goto QUIT;
  pass('private MySQL instance');
  
  # note('testing AutoDB created from socket on private MySQL instance');
  my $private_autodb=
    new Class::AutoDB(socket=>$socket_file,user=>$user,database=>'test',create=>1);
  ok($private_autodb,'AutoDB created from socket on private MySQL instance') or goto QUIT;
  
  # now make sure the public and private instances are different
  # note('testing public and private MySQL instances are different');
  # create table in public instance
  my $dbh=$autodb->dbh;
  do_sql($dbh,qq(CREATE TABLE test_table(xxx INT))) or goto QUIT;
  my @tables=tables($dbh,qw(test_table));
  report_fail(@tables==1,"table exists in public instance after CREATE") or goto QUIT;
  # delete table in private instance
  my $private_dbh=$private_autodb->dbh;
  do_sql($private_dbh,qq(DROP TABLE IF EXISTS test_table)) or goto QUIT;
  my @tables=tables($private_dbh,qw(test_table));
  report_fail(@tables==0,"table does not exist in private instance after DROP") or goto QUIT;
  my @tables=tables($dbh,qw(test_table));
  report_fail(@tables==1,"table still exists in public instance after DROP in private instance")
    or goto QUIT;
  pass('public and private MySQL instances are different');
}
QUIT:
pass('end of tests');		# to keep test harness happy
done_testing();

# check whether MySQL test database is accessible and we can do all necesssary ops
# set $errstr and return undef
# overkill here, but dry run for what we'll need in general case
sub check_mysql {
  my($dbh,$testdb)=@_;
  # try to create database if necessary, then use it
  # don't worry about create-errors: may be able to use even if can't create
  do_sql($dbh,qq(CREATE DATABASE IF NOT EXISTS $testdb));
  do_sql($dbh,qq(USE $testdb)) or return undef;

  # make sure we can do all necessary operations
  # create, alter, drop tables. insert, select, replace, update, select, delete
  # NG 10-11-19: ops on views needed for Babel, not AutoDB
  # NG 10-11-19: DROP tables and views if they exist
  do_sql($dbh,qq(DROP TABLE IF EXISTS test_table)) or return undef;
  do_sql($dbh,qq(DROP VIEW IF EXISTS test_table)) or return undef;
  do_sql($dbh,qq(DROP TABLE IF EXISTS test_view)) or return undef;
  do_sql($dbh,qq(DROP VIEW IF EXISTS test_view)) or return undef;
  my @tables=tables($dbh,qw(test_table test_view));
  report_fail(@tables==0,"@tables do not exist after 1st DROP") or return undef;

  do_sql($dbh,qq(CREATE TABLE test_table(xxx INT))) or return undef;
  do_sql($dbh,qq(ALTER TABLE test_table ADD COLUMN yyy INT)) or return undef;
  do_sql($dbh,qq(CREATE VIEW test_view AS SELECT * from test_table)) or return undef;
  my @tables=tables($dbh,qw(test_table test_view));
  report_fail(@tables==2,"@tables exist after CREATE") or return undef;
  # do drop at end, since we need table here
  do_sql($dbh,qq(INSERT INTO test_table(xxx) VALUES(123))) or return undef;
  do_sql($dbh,qq(REPLACE INTO test_table(xxx) VALUES(456))) or return undef;
  do_sql($dbh,qq(UPDATE test_table SET yyy=789 WHERE xxx=123)) or return undef;
  # check contents of test_table, test_view
  check_contents($dbh,'test_table',[[123,789],[456,undef]],'test_table before DELETE') 
    or return undef;
  check_contents($dbh,'test_view',[[123,789],[456,undef]],'test_view before DELETE') 
    or return undef;
  # DELETE then retest contents
  do_sql($dbh,qq(DELETE FROM test_table WHERE xxx=123)) or return undef;
  check_contents($dbh,'test_table',[[456,undef]],'test_table after DELETE') or return undef;
  check_contents($dbh,'test_view',[[456,undef]],'test_view after DELETE') or return undef;

  do_sql($dbh,qq(DROP VIEW IF EXISTS test_view)) or return undef;
  do_sql($dbh,qq(DROP TABLE IF EXISTS test_table)) or return undef;
  my @tables=tables($dbh,qw(test_table test_view));
  report_fail(@tables==0,"@tables do not exist after 2nd DROP") or return undef;
  # since we made it here, we can do everything!
  1;
}
sub tables {
  my($dbh,@want_tables)=@_;
  my $sql=qq(SHOW TABLES);
  my @tables=@{$dbh->selectcol_arrayref($sql)};
  report_fail(!$errstr,"execution of $sql. error=\n$errstr")  or return undef;
  if (@want_tables) {
    my $want_tables=join('|',map {'^'.$_.'$'} @want_tables);
    @tables=grep /$want_tables/,@tables;
  }
  wantarray? @tables: \@tables;
}
sub rows {
  my($dbh,$table,@columns)=@_;
  my $columns=@columns? join(',',@columns): '*';
  my $sql=qq(SELECT $columns FROM $table);
  my $rows=$dbh->selectall_arrayref($sql);
  report_fail(!$errstr,"execution of $sql. error=\n$errstr")  or return undef;
  wantarray? @$rows: $rows;
}
sub do_sql {
  my($dbh,$sql)=@_;
  $dbh->do($sql);
  $errstr=$dbh->errstr;
  report_fail(!$errstr,"execution of $sql. error=\n$errstr")  or return undef;
  1;
}
# check_contents of table or view
# query hard-coded for structure expected here
sub check_contents {
  my($dbh,$table,$correct,$label)=@_;
  my $actual=rows($dbh,$table,qw(xxx yyy)) or return undef;
  my($ok,$details)=cmp_details($actual,bag(@$correct));
  report_fail($ok,"contents of $label",__FILE__,__LINE__,$details);
  1;
}

# find mysql socket by running mysqladmin if possible
sub find_socket {
  # get path to mysqladmin
  my $mysqladmin=`which mysqladmin 2> /dev/null`;
  chomp $mysqladmin;
  unless (-x $mysqladmin) {
    my $paths=`whereis mysqladmin 2> /dev/null`;
    chomp $paths;
    $paths=~s/^mysqladmin: //;
    my @paths=split(/\s+/,$paths);
    $mysqladmin=first {-x $_} @paths;
  }
  return undef unless $mysqladmin;
  my $socket=`$mysqladmin variables 2> /dev/null | grep socket`;
  chomp $socket;
  $socket=~s/^.*?socket\s+\|\s*|\s+\|//g;
  return $socket || undef;
}
