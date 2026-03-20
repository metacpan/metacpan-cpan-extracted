######################################################################
#
# Tests IN, NOT IN, EXISTS, NOT EXISTS, scalar subqueries,
# derived tables, and correlated subqueries.
#
######################################################################

use strict;
BEGIN { $INC{'warnings.pm'} = '' if $] < 5.006 }; use warnings; local $^W=1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use FindBin ();
use lib "$FindBin::Bin/../lib";
use DB::Handy;

###############################################################################
# Embedded test harness (no Test::More dependency)
###############################################################################
my ($PASS, $FAIL, $T) = (0, 0, 0);
sub is      { my($g,$e,$n)=@_; $T++; defined($g)&&("$g" eq "$e") ? ($PASS++, print "ok $T - $n\n") : ($FAIL++, print "not ok $T - $n  (got='${\(defined $g?$g:'undef')}', exp='$e')\n") }
sub rows_ok { my($r,$c,$n)=@_; $T++; (ref($r) eq 'ARRAY')&&(@$r==$c) ? ($PASS++, print "ok $T - $n\n") : ($FAIL++, print "not ok $T - $n  (got=".(ref($r) eq 'ARRAY'?scalar@$r:'undef').", exp=$c)\n") }

print "1..43\n";
use File::Path ();

###############################################################################
# Data setup
###############################################################################
my $BASE = "/tmp/test_subq_$$";
File::Path::rmtree($BASE) if -d $BASE;

my $db = DB::Handy->new(base_dir => $BASE);
$db->create_database('sqtest');
$db->use_database('sqtest');

# departments
$db->execute("CREATE TABLE departments (id INT, name VARCHAR(64), budget INT)");
$db->execute("INSERT INTO departments (id,name,budget) VALUES (10,'Engineering',500000)");
$db->execute("INSERT INTO departments (id,name,budget) VALUES (20,'Sales',200000)");
$db->execute("INSERT INTO departments (id,name,budget) VALUES (30,'HR',150000)");
$db->execute("INSERT INTO departments (id,name,budget) VALUES (40,'Legal',100000)");

# employees
$db->execute("CREATE TABLE employees (id INT, name VARCHAR(64), dept_id INT, salary INT, mgr_id INT)");
$db->execute("INSERT INTO employees (id,name,dept_id,salary,mgr_id) VALUES (1,'Alice',10,90000,0)");
$db->execute("INSERT INTO employees (id,name,dept_id,salary,mgr_id) VALUES (2,'Bob',20,55000,1)");
$db->execute("INSERT INTO employees (id,name,dept_id,salary,mgr_id) VALUES (3,'Charlie',10,80000,1)");
$db->execute("INSERT INTO employees (id,name,dept_id,salary,mgr_id) VALUES (4,'Diana',30,62000,1)");
$db->execute("INSERT INTO employees (id,name,dept_id,salary,mgr_id) VALUES (5,'Eve',10,95000,0)");
$db->execute("INSERT INTO employees (id,name,dept_id,salary,mgr_id) VALUES (6,'Frank',20,48000,2)");
$db->execute("INSERT INTO employees (id,name,dept_id,salary,mgr_id) VALUES (7,'Grace',40,70000,1)");
$db->execute("INSERT INTO employees (id,name,dept_id,salary,mgr_id) VALUES (8,'Hank',10,72000,3)");

# salaries (historical)
$db->execute("CREATE TABLE salary_hist (emp_id INT, year INT, amount INT)");
$db->execute("INSERT INTO salary_hist (emp_id,year,amount) VALUES (1,2022,85000)");
$db->execute("INSERT INTO salary_hist (emp_id,year,amount) VALUES (1,2023,90000)");
$db->execute("INSERT INTO salary_hist (emp_id,year,amount) VALUES (2,2022,50000)");
$db->execute("INSERT INTO salary_hist (emp_id,year,amount) VALUES (3,2022,75000)");
$db->execute("INSERT INTO salary_hist (emp_id,year,amount) VALUES (5,2022,88000)");

# high_value_depts (simple lookup table)
$db->execute("CREATE TABLE high_value (dept_id INT)");
$db->execute("INSERT INTO high_value (dept_id) VALUES (10)");
$db->execute("INSERT INTO high_value (dept_id) VALUES (20)");

###############################################################################
# WHERE col IN (SELECT ...)
###############################################################################
my $res = $db->execute(
    "SELECT name FROM employees WHERE dept_id IN (SELECT id FROM departments WHERE budget > 200000)"
);
# departments with budget > 200000: Engineering(10), Sales(200000 is NOT > 200000)
# Only Engineering(10): Alice,Charlie,Eve,Hank

# ok 1
rows_ok($res->{data},, 4, "IN subquery: 4 Engineering employees");
my @names = sort map { $_->{name} } @{$res->{data}};

# ok 2
is(join(',',@names), 'Alice,Charlie,Eve,Hank', "IN subquery: correct names");

###############################################################################
# WHERE col NOT IN (SELECT ...)
###############################################################################
$res = $db->execute(
    "SELECT name FROM employees WHERE dept_id NOT IN (SELECT id FROM departments WHERE budget > 200000)"
);
# Non-engineering: Bob,Diana,Frank,Grace

# ok 3
rows_ok($res->{data},, 4, "NOT IN subquery: 4 non-Engineering employees");
@names = sort map { $_->{name} } @{$res->{data}};

# ok 4
is(join(',',@names), 'Bob,Diana,Frank,Grace', "NOT IN subquery: correct names");

###############################################################################
# IN with empty subquery result -> 0 rows
###############################################################################
$res = $db->execute(
    "SELECT name FROM employees WHERE dept_id IN (SELECT id FROM departments WHERE budget > 9999999)"
);

# ok 5
rows_ok($res->{data},, 0, "IN empty subquery -> 0 rows");

###############################################################################
# NOT IN with empty subquery result -> all rows
###############################################################################
$res = $db->execute(
    "SELECT name FROM employees WHERE dept_id NOT IN (SELECT id FROM departments WHERE budget > 9999999)"
);

# ok 6
rows_ok($res->{data},, 8, "NOT IN empty subquery -> all 8 rows");

###############################################################################
# IN with multi-value subquery
###############################################################################
$res = $db->execute(
    "SELECT name FROM employees WHERE dept_id IN (SELECT dept_id FROM high_value)"
);
# high_value has dept 10 and 20 -> Engineering + Sales = Alice,Bob,Charlie,Eve,Frank,Hank

# ok 7
rows_ok($res->{data},, 6, "IN multi-value: 6 employees in high-value depts");

###############################################################################
# WHERE col = (SELECT scalar)
###############################################################################
$res = $db->execute(
    "SELECT name FROM employees WHERE dept_id = (SELECT id FROM departments WHERE name = 'HR')"
);
# HR dept id = 30 -> Diana

# ok 8
rows_ok($res->{data},, 1, "scalar = subquery: 1 row");

# ok 9
is($res->{data}[0]{name}, 'Diana', "scalar = subquery: got Diana");

###############################################################################
# WHERE col > (SELECT scalar)
###############################################################################
$res = $db->execute(
    "SELECT name FROM employees WHERE salary > (SELECT salary FROM employees WHERE name = 'Alice')"
);
# Alice salary=90000; only Eve(95000) is higher

# ok 10
rows_ok($res->{data},, 1, "scalar > subquery: 1 row");

# ok 11
is($res->{data}[0]{name}, 'Eve', "scalar > subquery: got Eve");

###############################################################################
# WHERE col < (SELECT scalar)
###############################################################################
$res = $db->execute(
    "SELECT name FROM employees WHERE salary < (SELECT salary FROM employees WHERE name = 'Bob')"
);
# Bob=55000; Frank(48000) only

# ok 12
rows_ok($res->{data},, 1, "scalar < subquery: 1 row");

# ok 13
is($res->{data}[0]{name}, 'Frank', "scalar < subquery: got Frank");

###############################################################################
# WHERE col >= (SELECT scalar)
###############################################################################
$res = $db->execute(
    "SELECT name FROM employees WHERE salary >= (SELECT salary FROM employees WHERE name = 'Eve')"
);
# Eve=95000; only Eve herself

# ok 14
rows_ok($res->{data},, 1, "scalar >= subquery: 1 row (Eve)");

###############################################################################
# WHERE col != (SELECT scalar)
###############################################################################
$res = $db->execute(
    "SELECT name FROM employees WHERE dept_id != (SELECT id FROM departments WHERE name = 'Engineering')"
);
# dept_id != 10 -> Bob,Diana,Frank,Grace

# ok 15
rows_ok($res->{data},, 4, "scalar != subquery: 4 non-Engineering employees");

###############################################################################
# Scalar subquery returning 0 rows -> no match
###############################################################################
$res = $db->execute(
    "SELECT name FROM employees WHERE salary = (SELECT salary FROM employees WHERE name = 'Nobody')"
);

# ok 16
rows_ok($res->{data},, 0, "scalar subquery 0 rows -> no match");

###############################################################################
# WHERE EXISTS (SELECT ...)
###############################################################################
$res = $db->execute(
    "SELECT name FROM employees WHERE EXISTS (SELECT id FROM departments WHERE id = 10)"
);
# departments has id=10 -> EXISTS is TRUE -> all employees returned

# ok 17
rows_ok($res->{data},, 8, "EXISTS (non-correlated, always true) -> 8 rows");

###############################################################################
# WHERE NOT EXISTS (SELECT ...)
###############################################################################
$res = $db->execute(
    "SELECT name FROM employees WHERE NOT EXISTS (SELECT id FROM departments WHERE id = 9999)"
);
# No dept with id=9999 -> NOT EXISTS is TRUE -> all employees returned

# ok 18
rows_ok($res->{data},, 8, "NOT EXISTS (always true) -> 8 rows");

$res = $db->execute(
    "SELECT name FROM employees WHERE EXISTS (SELECT id FROM departments WHERE id = 9999)"
);

# ok 19
rows_ok($res->{data},, 0, "EXISTS (always false) -> 0 rows");

###############################################################################
# Correlated EXISTS (outer col referenced in inner WHERE)
###############################################################################
# Find employees who have a salary history record
$res = $db->execute(
    "SELECT name FROM employees WHERE EXISTS (SELECT emp_id FROM salary_hist WHERE emp_id = employees.id)"
);
# Employees with history: 1(Alice),2(Bob),3(Charlie),5(Eve) -> 4 rows

# ok 20
rows_ok($res->{data},, 4, "correlated EXISTS: 4 employees have salary history");
@names = sort map { $_->{name} } @{$res->{data}};

# ok 21
is(join(',',@names), 'Alice,Bob,Charlie,Eve', "correlated EXISTS: correct names");

###############################################################################
# Correlated NOT EXISTS
###############################################################################
$res = $db->execute(
    "SELECT name FROM employees WHERE NOT EXISTS (SELECT emp_id FROM salary_hist WHERE emp_id = employees.id)"
);
# Employees WITHOUT history: Diana(4),Frank(6),Grace(7),Hank(8) -> 4 rows

# ok 22
rows_ok($res->{data},, 4, "correlated NOT EXISTS: 4 employees have no salary history");
@names = sort map { $_->{name} } @{$res->{data}};

# ok 23
is(join(',',@names), 'Diana,Frank,Grace,Hank', "correlated NOT EXISTS: correct names");

###############################################################################
# FROM (SELECT ...) AS t -- basic derived table
###############################################################################
$res = $db->execute(
    "SELECT name FROM (SELECT name, salary FROM employees WHERE dept_id = 10) AS eng"
);
# Engineering employees: Alice,Charlie,Eve,Hank

# ok 24
rows_ok($res->{data},, 4, "derived table: 4 Engineering employees");

###############################################################################
# FROM (SELECT ...) AS t WHERE outer condition
###############################################################################
$res = $db->execute(
    "SELECT name FROM (SELECT name, salary FROM employees WHERE dept_id = 10) AS eng WHERE salary > 80000"
);
# Engineering with salary > 80000: Alice(90000), Eve(95000)

# ok 25
rows_ok($res->{data},, 2, "derived table + outer WHERE: Alice and Eve");
@names = sort map { $_->{name} } @{$res->{data}};

# ok 26
is(join(',',@names), 'Alice,Eve', "derived table + outer WHERE: correct names");

###############################################################################
# FROM (SELECT ...) AS t ORDER BY / LIMIT
###############################################################################
$res = $db->execute(
    "SELECT name FROM (SELECT name, salary FROM employees) AS all_emp ORDER BY salary LIMIT 3"
);

# ok 27
rows_ok($res->{data},, 3, "derived table + ORDER BY + LIMIT: 3 rows");
# Should be the 3 lowest salaries: Frank(48000),Bob(55000),Diana(62000)
@names = map { $_->{name} } @{$res->{data}};

# ok 28
is($names[0], 'Frank', "derived table ORDER BY LIMIT: first is Frank (lowest salary)");
# ok 29
is($names[2], 'Diana', "derived table ORDER BY LIMIT: third is Diana");

###############################################################################
# Derived table used as pre-filter
###############################################################################
$res = $db->execute(
    "SELECT name FROM (SELECT name, dept_id FROM employees WHERE salary > 70000) AS wellpaid WHERE dept_id = 10"
);
# Well-paid Engineering: Alice(90k), Charlie(80k), Eve(95k), Hank(72k)

# ok 30
rows_ok($res->{data},, 4, "derived table pre-filter + outer WHERE: 4 well-paid Engineering");

###############################################################################
# Scalar subquery in SELECT list
###############################################################################
$res = $db->execute(
    "SELECT name, (SELECT budget FROM departments WHERE id = 10) AS eng_budget FROM employees WHERE id = 1"
);

# ok 31
rows_ok($res->{data},, 1, "scalar subquery in SELECT list: 1 row");

# ok 32
is($res->{data}[0]{eng_budget}, 500000, "scalar subquery in SELECT: correct budget value");

###############################################################################
# Two-level nesting
###############################################################################
# Employees in departments whose id is in high_value
# high_value -> dept 10,20; Engineering and Sales employees
$res = $db->execute(
    "SELECT name FROM employees WHERE dept_id IN (SELECT id FROM departments WHERE id IN (SELECT dept_id FROM high_value))"
);

# ok 33
rows_ok($res->{data},, 6, "two-level nesting: 6 employees in high-value departments");

###############################################################################
# Three-level nesting
###############################################################################
# Find employees whose dept budget is the maximum among high-value departments
# Inner-most: max budget is Engineering=500000
# Level 2: find dept id with that budget
# Level 1: find employees in that dept
$res = $db->execute(
    "SELECT name FROM employees WHERE dept_id IN " .
    "(SELECT id FROM departments WHERE budget > " .
    "(SELECT budget FROM departments WHERE name = 'Sales'))"
);
# Sales budget=200000; depts with budget > 200000: Engineering(500000)
# Engineering employees: Alice,Charlie,Eve,Hank

# ok 34
rows_ok($res->{data},, 4, "three-level nesting: 4 Engineering employees");

###############################################################################
# Correlated IN (outer col in inner WHERE)
###############################################################################
# Employees who appeared in salary_hist with amount > their current salary - 10000
# i.e. find employees whose historical salary was at least (current - 10000)
$res = $db->execute(
    "SELECT name FROM employees WHERE id IN " .
    "(SELECT emp_id FROM salary_hist WHERE amount > 80000)"
);
# salary_hist records > 80000: Alice(85000,90000), Eve(88000)
# emp_ids: 1(Alice), 5(Eve)

# ok 35
rows_ok($res->{data},, 2, "correlated-style IN + salary_hist: Alice and Eve");
@names = sort map { $_->{name} } @{$res->{data}};

# ok 36
is(join(',',@names), 'Alice,Eve', "IN salary_hist > 80000: correct names");

###############################################################################
# Correlated scalar comparison (each row evaluates subquery)
###############################################################################
# Employees whose id matches the minimum id in their own department
# Using correlated reference: employees.dept_id referenced in inner WHERE
$res = $db->execute(
    "SELECT name FROM employees WHERE salary > (SELECT amount FROM salary_hist WHERE emp_id = employees.id AND year = 2022)"
);
# Alice: current=90000, 2022=85000 -> 90000 > 85000 YES
# Bob: current=55000, 2022=50000 -> YES
# Charlie: current=80000, 2022=75000 -> YES
# Eve: current=95000, 2022=88000 -> YES
# Others (Diana,Frank,Grace,Hank) have no 2022 history -> subquery returns empty -> no match

# ok 37
rows_ok($res->{data},, 4, "correlated scalar: 4 employees got a raise from 2022");
@names = sort map { $_->{name} } @{$res->{data}};

# ok 38
is(join(',',@names), 'Alice,Bob,Charlie,Eve', "correlated scalar: correct names");

###############################################################################
# Subquery inside JOIN query
###############################################################################
$res = $db->execute(
    "SELECT e.name, d.name " .
    "FROM employees AS e " .
    "INNER JOIN departments AS d ON e.dept_id = d.id " .
    "WHERE e.dept_id IN (SELECT id FROM departments WHERE budget > 200000)"
);
# Only Engineering(10) has budget > 200000 -> 4 rows

# ok 39
rows_ok($res->{data},, 4, "JOIN + IN subquery: 4 Engineering employees");

###############################################################################
# Regression tests
###############################################################################
$res = $db->execute("SELECT name FROM employees WHERE salary > 70000");
# Alice(90k), Charlie(80k), Eve(95k), Hank(72k) = 4 rows; Grace=70000 not included

# ok 40
rows_ok($res->{data},, 4, "Regression plain SELECT: salary > 70000 -> 4 rows");

$db->execute("CREATE UNIQUE INDEX idx_emp_id ON employees (id)");
$res = $db->execute("SELECT name FROM employees WHERE id = 5");

# ok 41
rows_ok($res->{data},, 1, "Regression index SELECT: id=5 -> 1 row");

# ok 42
is($res->{data}[0]{name}, 'Eve', "Regression index SELECT: got Eve");

$res = $db->execute(
    "SELECT e.name, d.name " .
    "FROM employees AS e " .
    "INNER JOIN departments AS d ON e.dept_id = d.id " .
    "WHERE e.id = 1"
);

# ok 43
rows_ok($res->{data},, 1, "Regression JOIN SELECT: id=1 -> 1 row");

###############################################################################
# Cleanup
###############################################################################
File::Path::rmtree($BASE);

exit($FAIL ? 1 : 0);
