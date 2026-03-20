######################################################################
#
# Tests INNER JOIN, LEFT JOIN, RIGHT JOIN, CROSS JOIN, table aliases,
# qualified column names, and multi-table chained joins.
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
sub ok      { my($c,$n)=@_; $T++; $c ? ($PASS++, print "ok $T - $n\n") : ($FAIL++, print "not ok $T - $n\n") }
sub is      { my($g,$e,$n)=@_; $T++; defined($g)&&("$g" eq "$e") ? ($PASS++, print "ok $T - $n\n") : ($FAIL++, print "not ok $T - $n  (got='${\(defined $g?$g:'undef')}', exp='$e')\n") }
sub rows_ok { my($r,$c,$n)=@_; $T++; (ref($r) eq 'ARRAY')&&(@$r==$c) ? ($PASS++, print "ok $T - $n\n") : ($FAIL++, print "not ok $T - $n  (got=".(ref($r) eq 'ARRAY'?scalar@$r:'undef').", exp=$c)\n") }

print "1..42\n";
use File::Path ();

###############################################################################
# Setup
###############################################################################
my $BASE = "/tmp/test_join_$$";
File::Path::rmtree($BASE) if -d $BASE;

my $db = DB::Handy->new(base_dir => $BASE);
$db->create_database('jtest');
$db->use_database('jtest');

# departments: id(INT), dept_name(VARCHAR(64)), location(VARCHAR(64))
$db->execute("CREATE TABLE departments (id INT, dept_name VARCHAR(64), location VARCHAR(64))");
$db->execute("INSERT INTO departments (id,dept_name,location) VALUES (10,'Engineering','Tokyo')");
$db->execute("INSERT INTO departments (id,dept_name,location) VALUES (20,'Sales','Osaka')");
$db->execute("INSERT INTO departments (id,dept_name,location) VALUES (30,'HR','Nagoya')");
$db->execute("INSERT INTO departments (id,dept_name,location) VALUES (40,'Legal','Tokyo')");
# dept 50 intentionally has no employees (for RIGHT JOIN test)
$db->execute("INSERT INTO departments (id,dept_name,location) VALUES (50,'Finance','Sapporo')");

# employees: id(INT), name(VARCHAR(64)), dept_id(INT), salary(INT)
$db->execute("CREATE TABLE employees (id INT, name VARCHAR(64), dept_id INT, salary INT)");
$db->execute("INSERT INTO employees (id,name,dept_id,salary) VALUES (1,'Alice',10,90000)");
$db->execute("INSERT INTO employees (id,name,dept_id,salary) VALUES (2,'Bob',20,55000)");
$db->execute("INSERT INTO employees (id,name,dept_id,salary) VALUES (3,'Charlie',10,80000)");
$db->execute("INSERT INTO employees (id,name,dept_id,salary) VALUES (4,'Diana',30,62000)");
$db->execute("INSERT INTO employees (id,name,dept_id,salary) VALUES (5,'Eve',10,95000)");
$db->execute("INSERT INTO employees (id,name,dept_id,salary) VALUES (6,'Frank',20,48000)");
# Employee 7 has dept_id=99 (no matching dept -> for LEFT JOIN NULL test)
$db->execute("INSERT INTO employees (id,name,dept_id,salary) VALUES (7,'Grace',99,70000)");

# projects: id(INT), proj_name(VARCHAR(64)), lead_emp_id(INT)
$db->execute("CREATE TABLE projects (id INT, proj_name VARCHAR(64), lead_emp_id INT)");
$db->execute("INSERT INTO projects (id,proj_name,lead_emp_id) VALUES (1,'Alpha',1)");
$db->execute("INSERT INTO projects (id,proj_name,lead_emp_id) VALUES (2,'Beta',3)");
$db->execute("INSERT INTO projects (id,proj_name,lead_emp_id) VALUES (3,'Gamma',2)");
$db->execute("INSERT INTO projects (id,proj_name,lead_emp_id) VALUES (4,'Delta',5)");

###############################################################################
# Basic INNER JOIN
###############################################################################
my $res = $db->execute(
    "SELECT e.name, d.dept_name " .
    "FROM employees AS e " .
    "INNER JOIN departments AS d ON e.dept_id = d.id"
);
# 6 employees have a matching dept (Grace has dept_id=99, no match)

# ok 1
rows_ok($res->{data}, 6, "INNER JOIN: 6 matched rows");

###############################################################################
# INNER JOIN with WHERE on left table (salary > 70000)
###############################################################################
$res = $db->execute(
    "SELECT e.name, d.dept_name " .
    "FROM employees AS e " .
    "INNER JOIN departments AS d ON e.dept_id = d.id " .
    "WHERE e.salary > 70000"
);

# ok 2
rows_ok($res->{data}, 3, "INNER JOIN + WHERE left: 3 rows (Alice,Charlie,Eve)");
my @names = sort map { $_->{'e.name'} } @{$res->{data}};

# ok 3
is(join(',', @names), 'Alice,Charlie,Eve', "INNER JOIN + WHERE left: correct names");

###############################################################################
# INNER JOIN with WHERE on right table
###############################################################################
$res = $db->execute(
    "SELECT e.name, d.dept_name " .
    "FROM employees AS e " .
    "INNER JOIN departments AS d ON e.dept_id = d.id " .
    "WHERE d.location = 'Tokyo'"
);
# Engineering(10)=Tokyo -> Alice,Charlie,Eve  plus  Legal(40)=Tokyo -> no employees

# ok 4
rows_ok($res->{data}, 3, "INNER JOIN + WHERE right (location=Tokyo): 3 rows");

###############################################################################
# INNER JOIN with WHERE on both sides
###############################################################################
$res = $db->execute(
    "SELECT e.name, e.salary " .
    "FROM employees AS e " .
    "INNER JOIN departments AS d ON e.dept_id = d.id " .
    "WHERE d.location = 'Tokyo' AND e.salary >= 90000"
);

# ok 5
rows_ok($res->{data}, 2, "INNER JOIN + WHERE both sides: 2 rows (Alice,Eve)");

###############################################################################
# INNER JOIN with qualified SELECT columns
###############################################################################
$res = $db->execute(
    "SELECT e.name, e.salary, d.dept_name, d.location " .
    "FROM employees e " .
    "INNER JOIN departments d ON e.dept_id = d.id " .
    "WHERE e.id = 1"
);

# ok 6
rows_ok($res->{data}, 1, "INNER JOIN qualified cols: 1 row");

# ok 7
is($res->{data}[0]{'e.name'},      'Alice',       "qualified e.name");

# ok 8
is($res->{data}[0]{'d.dept_name'}, 'Engineering', "qualified d.dept_name");

# ok 9
is($res->{data}[0]{'d.location'},  'Tokyo',       "qualified d.location");

###############################################################################
# INNER JOIN: no match -> 0 rows
###############################################################################
$res = $db->execute(
    "SELECT e.name FROM employees AS e " .
    "INNER JOIN departments AS d ON e.dept_id = d.id " .
    "WHERE e.name = 'Grace'"
);

# ok 10
rows_ok($res->{data}, 0, "INNER JOIN: Grace has no matching dept -> 0 rows");

###############################################################################
# INNER JOIN with ORDER BY
###############################################################################
$res = $db->execute(
    "SELECT e.name, e.salary " .
    "FROM employees AS e " .
    "INNER JOIN departments AS d ON e.dept_id = d.id " .
    "ORDER BY e.salary"
);

# ok 11
rows_ok($res->{data}, 6, "INNER JOIN + ORDER BY: 6 rows");
my @salaries = map { $_->{'e.salary'} } @{$res->{data}};
my $sorted_ok = 1;
for my $i (1..$#salaries) {
    $sorted_ok = 0 if $salaries[$i] < $salaries[$i-1];
}

# ok 12
ok($sorted_ok, "ORDER BY e.salary ASC is correct");

###############################################################################
# INNER JOIN with LIMIT / OFFSET
###############################################################################
$res = $db->execute(
    "SELECT e.name, e.salary " .
    "FROM employees AS e " .
    "INNER JOIN departments AS d ON e.dept_id = d.id " .
    "ORDER BY e.salary " .
    "LIMIT 2 OFFSET 1"
);

# ok 13
rows_ok($res->{data}, 2, "INNER JOIN + LIMIT 2 OFFSET 1: 2 rows");

###############################################################################
# Table alias with AS keyword (already tested above); test without AS
###############################################################################
$res = $db->execute(
    "SELECT e.name FROM employees e INNER JOIN departments d ON e.dept_id = d.id WHERE e.id = 2"
);

# ok 14
rows_ok($res->{data}, 1, "INNER JOIN alias without AS");

# ok 15
is($res->{data}[0]{'e.name'}, 'Bob', "alias without AS: got Bob");

###############################################################################
# LEFT JOIN: all left rows returned (including Grace with no dept match)
###############################################################################
$res = $db->execute(
    "SELECT e.name, d.dept_name " .
    "FROM employees AS e " .
    "LEFT JOIN departments AS d ON e.dept_id = d.id"
);

# ok 16
rows_ok($res->{data}, 7, "LEFT JOIN: all 7 employees returned");

###############################################################################
# LEFT JOIN: unmatched right side is NULL
###############################################################################
$res = $db->execute(
    "SELECT e.name, d.dept_name " .
    "FROM employees AS e " .
    "LEFT JOIN departments AS d ON e.dept_id = d.id " .
    "WHERE e.name = 'Grace'"
);

# ok 17
rows_ok($res->{data}, 1, "LEFT JOIN Grace: 1 row");

# ok 18
ok(!defined $res->{data}[0]{'d.dept_name'}, "LEFT JOIN unmatched: d.dept_name is undef/NULL");

###############################################################################
# LEFT JOIN with WHERE (post-join filter on right side)
###############################################################################
$res = $db->execute(
    "SELECT e.name, d.location " .
    "FROM employees AS e " .
    "LEFT JOIN departments AS d ON e.dept_id = d.id " .
    "WHERE d.location = 'Osaka'"
);

# ok 19
rows_ok($res->{data}, 2, "LEFT JOIN + WHERE right: 2 Osaka employees");

###############################################################################
# RIGHT JOIN: all right rows returned (including Finance with no employees)
###############################################################################
$res = $db->execute(
    "SELECT e.name, d.dept_name " .
    "FROM employees AS e " .
    "RIGHT JOIN departments AS d ON e.dept_id = d.id"
);
# Depts: Eng(3 emp), Sales(2 emp), HR(1 emp), Legal(0 emp), Finance(0 emp) = 6+1+1 = 8?
# Actually: 3+2+1+1+1 = 8 rows (Legal and Finance each appear once with NULL emp)

# ok 20
rows_ok($res->{data}, 8, "RIGHT JOIN: 8 rows (6 matched + Legal NULL + Finance NULL)");

###############################################################################
# RIGHT JOIN: unmatched left side -> NULL
###############################################################################
my @right_only = grep { !defined $_->{'e.name'} } @{$res->{data}};

# ok 21
is(scalar @right_only, 2, "RIGHT JOIN: 2 rows with NULL employee (Legal, Finance)");

###############################################################################
# CROSS JOIN: Cartesian product
###############################################################################
$db->execute("CREATE TABLE colors (color VARCHAR(20))");
$db->execute("INSERT INTO colors (color) VALUES ('Red')");
$db->execute("INSERT INTO colors (color) VALUES ('Blue')");
$db->execute("CREATE TABLE sizes (size VARCHAR(20))");
$db->execute("INSERT INTO sizes (size) VALUES ('S')");
$db->execute("INSERT INTO sizes (size) VALUES ('M')");
$db->execute("INSERT INTO sizes (size) VALUES ('L')");

$res = $db->execute(
    "SELECT c.color, s.size " .
    "FROM colors AS c " .
    "CROSS JOIN sizes AS s ON c.color = c.color"
);

# ok 22
rows_ok($res->{data}, 6, "CROSS JOIN: 2 colors x 3 sizes = 6 rows");

###############################################################################
# 3-table INNER JOIN chain
###############################################################################
$res = $db->execute(
    "SELECT e.name, d.dept_name, p.proj_name " .
    "FROM employees AS e " .
    "INNER JOIN departments AS d ON e.dept_id = d.id " .
    "INNER JOIN projects AS p ON e.id = p.lead_emp_id"
);
# Projects led by: Alice(1), Charlie(3), Bob(2), Eve(5)  -- all have matching depts

# ok 23
rows_ok($res->{data}, 4, "3-table INNER JOIN: 4 rows");
my @pnames = sort map { $_->{'p.proj_name'} } @{$res->{data}};

# ok 24
is(join(',', @pnames), 'Alpha,Beta,Delta,Gamma', "3-table JOIN: correct project names");

###############################################################################
# 3-table: LEFT + INNER mixed
###############################################################################
$res = $db->execute(
    "SELECT e.name, d.dept_name, p.proj_name " .
    "FROM employees AS e " .
    "LEFT JOIN departments AS d ON e.dept_id = d.id " .
    "INNER JOIN projects AS p ON e.id = p.lead_emp_id"
);
# Only employees who lead a project AND the INNER JOIN with projects succeeds

# ok 25
rows_ok($res->{data}, 4, "LEFT+INNER 3-table: 4 rows");

###############################################################################
# SELECT alias.*  expansion
###############################################################################
$res = $db->execute(
    "SELECT e.*, d.dept_name " .
    "FROM employees AS e " .
    "INNER JOIN departments AS d ON e.dept_id = d.id " .
    "WHERE e.id = 1"
);

# ok 26
rows_ok($res->{data}, 1, "SELECT e.*: 1 row");

# ok 27
ok(exists $res->{data}[0]{'e.id'},     "e.* includes e.id");

# ok 28
ok(exists $res->{data}[0]{'e.name'},   "e.* includes e.name");

# ok 29
ok(exists $res->{data}[0]{'e.salary'}, "e.* includes e.salary");

# ok 30
ok(exists $res->{data}[0]{'d.dept_name'}, "d.dept_name also present");

###############################################################################
# SELECT * expansion (all tables)
###############################################################################
$res = $db->execute(
    "SELECT * " .
    "FROM employees AS e " .
    "INNER JOIN departments AS d ON e.dept_id = d.id " .
    "WHERE e.id = 2"
);

# ok 31
rows_ok($res->{data}, 1, "SELECT *: 1 row");

# ok 32
ok(exists $res->{data}[0]{'e.name'},      "SELECT * includes e.name");

# ok 33
ok(exists $res->{data}[0]{'d.dept_name'}, "SELECT * includes d.dept_name");

###############################################################################
# Qualified alias.col in WHERE
###############################################################################
$res = $db->execute(
    "SELECT e.name " .
    "FROM employees AS e " .
    "INNER JOIN departments AS d ON e.dept_id = d.id " .
    "WHERE d.dept_name = 'Engineering' AND e.salary > 85000"
);

# ok 34
rows_ok($res->{data}, 2, "Qualified WHERE: 2 rows (Alice,Eve in Engineering >85k)");

###############################################################################
# Both tables share a column name (id) -- qualified names disambiguate
###############################################################################
$res = $db->execute(
    "SELECT e.id, d.id, e.name " .
    "FROM employees AS e " .
    "INNER JOIN departments AS d ON e.dept_id = d.id " .
    "WHERE e.id = 1"
);

# ok 35
rows_ok($res->{data}, 1, "Duplicate col name 'id': 1 row");

# ok 36
is($res->{data}[0]{'e.id'}, 1,  "e.id = 1");

# ok 37
is($res->{data}[0]{'d.id'}, 10, "d.id = 10 (Engineering)");

###############################################################################
# ORDER BY alias.col DESC
###############################################################################
$res = $db->execute(
    "SELECT e.name, e.salary " .
    "FROM employees AS e " .
    "INNER JOIN departments AS d ON e.dept_id = d.id " .
    "ORDER BY e.salary DESC LIMIT 3"
);

# ok 38
rows_ok($res->{data}, 3, "ORDER BY DESC LIMIT: 3 rows");
my @desc_sal = map { $_->{'e.salary'} } @{$res->{data}};

# ok 39
ok($desc_sal[0] >= $desc_sal[1] && $desc_sal[1] >= $desc_sal[2],
   "ORDER BY e.salary DESC is correct");

###############################################################################
# Regression: plain SELECT still works
###############################################################################
$res = $db->execute("SELECT * FROM employees WHERE salary > 80000");

# ok 40
rows_ok($res->{data}, 2, "Plain SELECT regression: salary>80000 -> Alice(90k),Eve(95k)");

###############################################################################
# Regression: index-based SELECT still works
###############################################################################
$db->execute("CREATE UNIQUE INDEX idx_emp_id ON employees (id)");
$res = $db->execute("SELECT * FROM employees WHERE id = 3");

# ok 41
rows_ok($res->{data}, 1, "Index SELECT regression: id=3");

# ok 42
is($res->{data}[0]{name}, 'Charlie', "Index SELECT: got Charlie");

###############################################################################
# Cleanup
###############################################################################
File::Path::rmtree($BASE);

exit($FAIL ? 1 : 0);
