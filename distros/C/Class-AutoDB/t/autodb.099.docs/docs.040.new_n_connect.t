use t::lib;
use strict;
use Carp;
use Test::More;
use Test::Deep;
use Class::AutoDB;
use autodbUtil;

# test methods in METHODS/'new' and managing database connections

########################################
# test 'new' forms 
use Person;
my @usual_tables=qw(_AutoDB Person);

my $autodb=new Class::AutoDB(database=>testdb);
is(ref $autodb,'Class::AutoDB',"new .. database=>testdb");
test_single('Person',qw(Person)); # put a Person to make sure it worked

eval {
  my $autodb=new Class::AutoDB database=>testdb,host=>'localhost',user=>'fake',password=>'fake';};
ok($@,"new .. user=>'fake' failed as expected");

my $autodb=new Class::AutoDB database=>testdb,create=>1;
is(ref $autodb,'Class::AutoDB',"new .. database=>testdb,create=>1");
my @actual_tables=actual_tables(@usual_tables);
cmp_bag(\@actual_tables,\@usual_tables,"new .. database=>testdb,create=>1: tables");
my %actual_counts=actual_counts(@usual_tables);
cmp_deeply(\%actual_counts,{_AutoDB=>1,Person=>0},"new .. database=>testdb,create=>1: counts");
test_single('Person',qw(Person)); # put a Person to make sure it worked
my %actual_counts=actual_counts(@usual_tables);
cmp_deeply(\%actual_counts,{_AutoDB=>2,Person=>1},
	   "new .. database=>testdb,create=>1: counts after put");

my $autodb=new Class::AutoDB database=>testdb,drop=>1;
is(ref $autodb,'Class::AutoDB',"new .. database=>testdb,drop=>1");
my @actual_tables=actual_tables(qw(_AutoDB));
cmp_bag(\@actual_tables,[qw(_AutoDB)],"new .. database=>testdb,drop=>1: tables");
my %actual_counts=actual_counts(@usual_tables);
cmp_deeply(\%actual_counts,{_AutoDB=>1,Person=>0},"new .. database=>testdb,drop=>1: counts");

my $autodb=new Class::AutoDB database=>testdb,alter=>1;
is(ref $autodb,'Class::AutoDB',"new .. database=>testdb,alter=>1");
my @actual_tables=actual_tables(qw(_AutoDB));
cmp_bag(\@actual_tables,[qw(_AutoDB)],"new .. database=>testdb,alter=>1: tables");
my %actual_counts=actual_counts(@usual_tables);
cmp_deeply(\%actual_counts,{_AutoDB=>1,Person=>0},"new .. database=>testdb,alter=>1: counts");

my $autodb=new Class::AutoDB database=>testdb,read_only_schema=>1;
is(ref $autodb,'Class::AutoDB',"new .. database=>testdb,read_only_schema=>1");
my @actual_tables=actual_tables(qw(_AutoDB));
cmp_bag(\@actual_tables,[qw(_AutoDB)],"new .. database=>testdb,read_only_schema=>1: tables");
my %actual_counts=actual_counts(@usual_tables);
cmp_deeply(\%actual_counts,{_AutoDB=>1,Person=>0},
	   "new .. database=>testdb,read_only_schema=>1: counts");
eval {
  $autodb->register(collections=>{Person=>qq(name string, sex string, id integer),
				  HasName=>'name'});};
ok($@,"register on read_only_schema failed as expected");

########################################
# test attributes documented in METHODS
my $autodb=new Class::AutoDB(database=>testdb);

is($autodb->database,testdb,'database');
is($autodb->host,'localhost','host');
is($autodb->server,'localhost','server');
is($autodb->user,$ENV{USER},'user');
is($autodb->password,undef,'password');
is($autodb->pass,undef,'pass');
is($autodb->dbd,'mysql','dbd');
is($autodb->dsn,'DBI:mysql:database='.testdb.';host=localhost','dsn');
is($autodb->socket,undef,'socket');
is($autodb->sock,undef,'sock');
is($autodb->port,undef,'port');
is(ref $autodb->dbh,'DBI::db','dbh');
is($autodb->timeout(23456),23456,'timeout: set');
is($autodb->timeout,23456,'timeout: get');
is($autodb->read_only_schema,undef,'read_only_schema when not set');

my $autodb=new Class::AutoDB(database=>testdb,read_only_schema=>1);
is($autodb->read_only_schema,1,'read_only_schema when set');

########################################
# renew
my $autodb=new Class::AutoDB(database=>testdb);
my $renew=$autodb->renew(read_only_schema=>1);
is($renew,$autodb,'renew returned self');
is($renew->read_only_schema,1,'renew set attributes');

########################################
# test connection management methods
my $autodb=new Class::AutoDB(database=>testdb);
my $old_dbh=$autodb->dbh;
is($autodb->connect,$old_dbh,"connect w/o args");
is($autodb->connect(database=>testdb),$old_dbh,"connect w/ args");
is($autodb->disconnect,undef,'disconnect');
my $new_dbh=$autodb->reconnect;
is(ref $new_dbh,'DBI::db','reconnect w/o args: returned DBH');
isnt($new_dbh,$old_dbh,'reconnect w/o args: returned new DBH');
my $new_dbh=$autodb->reconnect(database=>testdb);
is(ref $new_dbh,'DBI::db','reconnect w/ args: returned DBH');
isnt($new_dbh,$old_dbh,'reconnect w/ args: returned new DBH');
ok($autodb->is_connected,'is_connected');
ok($autodb->ping,'ping');

done_testing();

