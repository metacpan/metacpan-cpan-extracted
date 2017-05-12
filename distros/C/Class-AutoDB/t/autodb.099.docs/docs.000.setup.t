use t::lib;
use strict;
use Carp;
use Test::More;
use autodbUtil;

use Class::AutoDB;
use_ok('Person');

# create AutoDB database
my $autodb=new Class::AutoDB(database=>testdb,create=>1); 
isa_ok($autodb,'Class::AutoDB','class is Class::AutoDB - sanity check');

# create 'human-engineered' tables
#   Dept(id int, name varchar(255)), EmpDept(emp_id int, dept_id int)

dbh->do(qq(DROP TABLE IF EXISTS Dept));
dbh->do(qq(DROP TABLE IF EXISTS EmpDept));
dbh->do(qq(CREATE TABLE Dept(id INT, name VARCHAR(255))));
dbh->do(qq(CREATE TABLE EmpDept(emp_id INT, dept_id INT)));
dbh->do(qq(INSERT INTO Dept VALUES(1,'toy'),(2,'pet')));
dbh->do(qq(INSERT INTO EmpDept VALUES(1,1),(1,2),(2,2),(3,1)));
my($count)=dbh->selectrow_array(qq(SELECT COUNT(*) FROM Dept));
is($count,2,'Dept');
my($count)=dbh->selectrow_array(qq(SELECT COUNT(*) FROM EmpDept));
is($count,4,'EmpDept');

# create SDBM files
tie_oid('create');

done_testing();

