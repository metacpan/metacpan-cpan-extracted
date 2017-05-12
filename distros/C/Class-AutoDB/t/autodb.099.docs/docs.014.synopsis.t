use t::lib;
use strict;
use Carp;
use Test::More;
use Test::Deep;
use autodbUtil;

# new features in verion 1.20
use Class::AutoDB;
use Person;
my $autodb=new Class::AutoDB(database=>testdb); # open database
isa_ok($autodb,'Class::AutoDB','class is Class::AutoDB - sanity check');

# retrieve objects using SQL
# assuming the above database (with human-engineered tables Dept and EmpDept),
# this query retrieves Person objects for employees in the toy department
my @toy_persons=
  $autodb->get
  (sql=>qq(SELECT oid FROM Dept, EmpDept, Person 
           WHERE Dept.id=EmpDept.dept_id AND EmpDept.emp_id=Person.id 
           AND Dept.name='toy'));
my($joe)=$autodb->get(collection=>'Person',name=>'Joe');
my($bill)=$autodb->get(collection=>'Person',name=>'Bill');
cmp_deeply(\@toy_persons,bag($joe,$bill),'retrieve objects using SQL');

# retrieve all objects
my($mary)=$autodb->get(collection=>'Person',name=>'Mary');
my @all_objects=$autodb->get;
cmp_deeply(\@all_objects,bag($joe,$mary,$bill),'retrieve all objects');

done_testing();

