use t::lib;
use strict;
use Carp;
use Test::More;
use Test::Deep;
use autodbUtil;

# connect auto-persistent objects with engineered tables
# assume database has human-engineered tables
#   Dept(id int, name varchar(255)), EmpDept(emp_id int, dept_id int)
use Class::AutoDB;
use Person;
my $autodb=new Class::AutoDB(database=>testdb); # open database
isa_ok($autodb,'Class::AutoDB','class is Class::AutoDB - sanity check');

# this query retrieves the names of Joe's departments
use DBI;
my $dbh=$autodb->dbh;
my $depts=$dbh->selectcol_arrayref
  (qq(SELECT Dept.name FROM Dept, EmpDept, Person 
      WHERE Dept.id=EmpDept.dept_id AND EmpDept.emp_id=Person.id 
      AND Person.name='Joe'));
cmp_deeply($depts,bag(qw(toy pet)),'connect auto-persistent objects with engineered tables');

done_testing();

