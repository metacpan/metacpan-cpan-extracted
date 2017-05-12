# Regression test: deal with views everywhere that we create or drop tables...

package Test;
use base qw(Class::AutoClass);
use vars qw(@AUTO_ATTRIBUTES %AUTODB);
@AUTO_ATTRIBUTES=qw(name strings);
%AUTODB=1;
# %AUTODB=(collection=>'Test', 
# 	 keys=>qq(id integer, name strings));
Class::AutoClass::declare;

package main;
use t::lib;
use strict;
use Carp;
use Test::More;
use Test::Deep;
use DBI;
use Class::AutoDB;
use autodbUtil;

our $sql_errstr;
sub do_sql {
  my($dbh,@sql)=@_;
  for my $sql (@sql) {
    $dbh->do($sql);
    if ($dbh->err) {
      $sql_errstr="error running SQL statement: $sql\nerror message: ".$dbh->errstr;
      return undef;
    }}
  1;
}

ok(1,'start');			# ensure that at least 1 test runs
# NG 10-09-17: only run if MySQL version >= 5.0.1, since views not supported before then
# NG 10-09-18: skip if create view fails for any reason. report reason
my $dbh=DBI->connect("dbi:mysql:database=".testdb,undef,undef,
                     {AutoCommit=>1, ChopBlanks=>1, PrintError=>0, PrintWarn=>0, Warn=>0,});
report_fail(!$DBI::err,"connecting to MySQL: $DBI::errstr",__FILE__,__LINE__);

my($mysql)=$dbh->selectrow_array(qq(SELECT VERSION()));
report_fail(!$DBI::err,"getting MySQL version: $DBI::errstr",__FILE__,__LINE__);

my $ok=1;
my @vparts=$mysql=~/(\d+)/g;	# split into numeric components
$ok=0 unless shift(@vparts)>=5;	# major version must be >= 5
shift @vparts;			# 2nd component can be anything
$ok=0 unless shift(@vparts)>=1;	# 3rd component must be >= 1
unless ($ok) {
  diag("test skipped\nMySQL version $mysql doesn't support views");
} else {
  # create views that will get in the way
  # # need $dbh to do so.
  # my $dbh=DBI->connect("dbi:mysql:database=test",undef,undef,
  #                      {AutoCommit=>1, ChopBlanks=>1, PrintError=>0, PrintWarn=>0, Warn=>0,});
  # report_fail(!$DBI::err,"connecting to MySQL: $DBI::errstr",__FILE__,__LINE__);
  # NG 10-09-17: added _AutoDB
  my @views=qw(_AutoDB Test Test_strings);
  my $views=join(',',@views);
  my @sql=map {(qq(DROP TABLE IF EXISTS $_),qq(DROP VIEW IF EXISTS $_),
		qq(CREATE VIEW $_ AS SELECT 1 AS test))} @views;
  # NG 10-09-18: check for errors as we go. if error, report and skip test
  # map {$dbh->do($_)} @sql;
  $ok=do_sql($dbh,@sql);
  unless ($ok) {
    diag("test skipped\n$sql_errstr");
  } else {	    # no complaints while doing the SQL
    # make sure it worked. report and skip test if not
    # my $tables=$dbh->selectcol_arrayref(qq(SHOW TABLES)); #  return ARRAY ref of table names
    my(@oks,@bads);
    for my $view (@views) {
      my($table)=$dbh->selectrow_array(qq(SHOW TABLES LIKE '$view'));
      if ($table eq $view) { 
	push(@oks,$view);
      } else {
	push(@bads,$view);
      }}
    if (@bads) {
      diag(join("\n",
		"test skipped",
		"view creation failed for no apparent reason",
		"  able to create views: @oks",
		"unable to create views: @bads"));
    } else {
      # regression test starts here
      # create AutoDB
      my $autodb=eval {new Class::AutoDB(database=>testdb,create=>1);};
      my $ok=report_fail(!$@,"create AutoDB\n$@");
      if ($ok) {    # only continue if AutoDB exists. futile otherwise
	isa_ok($autodb,'Class::AutoDB','create AutoDB');
	
	# re-open $autodb in alter mode
	my $autodb=new Class::AutoDB(database=>testdb,alter=>1);
	isa_ok($autodb,'Class::AutoDB','class is Class::AutoDB - sanity check');
	# create
	eval {$autodb->register(class=>'Test',collection=>'Test',keys=>qq(name string));};
	my $ok=report_fail(!$@,"create failed: $@",__FILE__,__LINE__);
	report_pass($ok,'create');
	# alter
	eval 
	  {$autodb->register(class=>'Test',collection=>'Test',keys=>qq(strings list(string)));};
	my $ok=report_fail(!$@,"alter failed: $@",__FILE__,__LINE__);
	report_pass($ok,'alter');

	# make sure it worked by putting an object and checking database
	my $object=new Test name=>'test',strings=>[qw(hello world)];
	$autodb->put($object);
	my($count)=$dbh->selectrow_array(qq(SELECT COUNT(*) FROM Test));
	is($count,1,'number of rows in Test table');
	my($count)=$dbh->selectrow_array(qq(SELECT COUNT(*) FROM Test_strings));
	is($count,2,'number of rows in Test_strings table');
	my $rows=$dbh->selectall_arrayref
	  (qq(SELECT name,strings FROM Test NATURAL JOIN Test_strings));
	my @correct=([qw(test hello)],[qw(test world)]);
	cmp_deeply($rows,bag(@correct),'data in Test and Test_strings tables');
      }}}}

done_testing();




