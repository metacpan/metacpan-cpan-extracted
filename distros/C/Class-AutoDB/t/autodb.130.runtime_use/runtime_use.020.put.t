# Regression test: runtime use. 020, 021 test put & del
# all classes use the same collection. 
# the 'put' test stores objects of different classes in 'top' object's list attribute
# the 'del' test gets 'top' then deletes objects from list
#   some cases should be okay; others should fail 

use t::lib;
use strict;
use Carp;
use Test::More;
use Class::AutoDB;
use autodbTestObject;
use autodbUtil;

use CompileTimeUse; use RunTimeUseOk; use RunTimeUseBad;

# create AutoDB database & SDBM files
my $autodb=new Class::AutoDB(database=>testdb,create=>1); 
isa_ok($autodb,'Class::AutoDB','class is Class::AutoDB - sanity check');
tie_oid('create');

# make the objects. 
my $top=new CompileTimeUse(name=>'top',id=>id_next());
my @objects=
  (new CompileTimeUse(name=>'compile time use',id=>id_next()),
   new RunTimeUseOk(name=>'runtime use okay',id=>id_next()),
   new RunTimeUseNotOk(name=>'runtime use not okay',id=>id_next()));
$top->list(\@objects);

my %test_args=
  (class2colls=>{CompileTimeUse=>[qw(HasName)],
		 RunTimeUseOk=>[qw(HasName)],
		 RunTimeUseNotOk=>[qw(HasName)]},
   coll2keys=>{HasName=>[[qw(id name)],[]]},
   correct_diffs=>1,
   label=>sub {my $object=$_[0]->current_object; $object->name if $object;});

my $test=new autodbTestObject(%test_args);
$test->test_put(labelprefix=>'put:',objects=>[$top,@objects]);

done_testing();
