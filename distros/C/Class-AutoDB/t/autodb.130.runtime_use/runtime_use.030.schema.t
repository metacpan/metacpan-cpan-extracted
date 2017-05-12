# Regression test: runtime use of class that changes schema

use t::lib;
use strict;
use Carp;
use Test::More;
use Class::AutoDB;
use autodbTestObject;
use autodbUtil;

use CompileTimeUse;		# defines collection HasName

# drop collection tables manually 
my @correct_tables=qw(HasName RunTimeUseCollection);
map {dbh->do(qq(DROP TABLE IF EXISTS $_))} @correct_tables;
is(scalar(actual_tables(@correct_tables)),0,'at start: collection tables do not exist');

# create AutoDB database & SDBM files
my $autodb=new Class::AutoDB(database=>testdb,create=>1); 
isa_ok($autodb,'Class::AutoDB','class is Class::AutoDB - sanity check');
tie_oid('create');

# collection HasName should exist. RunTimeUseCollection should not exist
my($table)=dbh->selectrow_array(qq(SHOW TABLES LIKE 'HasName'));
is($table,'HasName','before runtime use: table HasName exists');
my($table)=dbh->selectrow_array(qq(SHOW TABLES LIKE 'RunTimeUseCollection'));
ok(!$table,'before runtime use: table RunTimeUseCollection does not exist as expected');

# now use class RunTimeUseCollection - should create collection
eval "use RunTimeUseCollection";
if ($@) {			# 'use' failed
  fail('use RunTimeUseCollection');
  diag($@);
  BAIL_OUT('cannot proceed without using RunTimeUseCollection');
}
my($table)=dbh->selectrow_array(qq(SHOW TABLES LIKE 'RunTimeUseCollection'));
is($table,'RunTimeUseCollection','after runtime use: table RunTimeUseCollection exists');

# make and test some objects. 
my @objects=
  (new CompileTimeUse(name=>'compile time use',id=>id_next()),
   new RunTimeUseCollection(name=>'runtime use collection',id=>id_next()));

my %test_args=
  (class2colls=>{CompileTimeUse=>[qw(HasName)],
                 RunTimeUseCollection=>[qw(HasName RunTimeUseCollection)]},
   coll2keys=>{HasName=>[[qw(id name)],[]],
	       RunTimeUseCollection=>[[qw(id name)],[]]},
   correct_diffs=>1,
   label=>sub {my $object=$_[0]->current_object; $object->name if $object;});

my $test=new autodbTestObject(%test_args);
$test->test_put(labelprefix=>'put:',objects=>\@objects);

done_testing();
