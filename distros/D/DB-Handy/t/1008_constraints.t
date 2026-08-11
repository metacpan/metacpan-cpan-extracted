######################################################################
#
# Tests column constraints: NOT NULL, DEFAULT, CHECK, PRIMARY KEY,
# UNIQUE, and their interaction with INSERT/UPDATE/VACUUM.
#
# NOT NULL   -- rejected on INSERT and UPDATE
# DEFAULT    -- applied when column is omitted or empty
# CHECK      -- evaluated on INSERT and UPDATE
# PRIMARY KEY -- implies NOT NULL and a UNIQUE index named <col>_pk
# UNIQUE      -- column or table constraint; index named <col>_unique
# UNIQUE via CREATE UNIQUE INDEX -- enforced on INSERT and UPDATE
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
my @OUT;          # buffered ok() lines
my $DONE = 0;     # set once the plan has been emitted
sub ok  { my($c, $n)=@_; $T++; $c ? ($PASS++, push @OUT, "ok $T - $n\n") : ($FAIL++, push @OUT, "not ok $T - $n\n") }
sub is  { my($g, $e, $n)=@_; $T++; defined($g)&&("$g" eq "$e") ? ($PASS++, push @OUT, "ok $T - $n\n") : ($FAIL++, push @OUT, "not ok $T - $n  (got='${\ (defined $g?$g:'undef')}', exp='$e')\n") }

use File::Path ();
use File::Spec ();
my $BASE = File::Spec->catdir(File::Spec->tmpdir, "test_constraints_$$");
File::Path::rmtree($BASE) if -d $BASE;

# Remove the scratch directory however the script leaves: a normal exit,
# a die in mid-file, or an interrupt.  Without this an aborted run left a
# stale tree behind in the system temp directory.
END { File::Path::rmtree($BASE) if defined($BASE) && -d $BASE }

my $db = DB::Handy->new(base_dir => $BASE);
$db->create_database('ctest');
$db->use_database('ctest');

###############################################################################
# NOT NULL: INSERT violation
###############################################################################
$db->execute("CREATE TABLE nn (id INT NOT NULL, name VARCHAR(20))");

my $res = $db->execute("INSERT INTO nn (id,name) VALUES (1,'Alice')");
# ok 1
ok($res->{type} eq 'ok', "NOT NULL: valid INSERT ok");

# Omit the NOT NULL column -> error
$res = $db->execute("INSERT INTO nn (name) VALUES ('Bob')");
# ok 2
ok($res->{type} eq 'error', "NOT NULL: INSERT omitting NOT NULL col fails");
# ok 3
ok(($res->{message} =~ /NOT NULL/) ? 1 : 0, "NOT NULL: error message mentions NOT NULL");

# Explicit empty string also violates NOT NULL
$res = $db->execute("INSERT INTO nn (id,name) VALUES ('','Carol')");
# ok 4
ok($res->{type} eq 'error', "NOT NULL: INSERT with empty string fails");

###############################################################################
# NOT NULL: UPDATE violation
###############################################################################
$res = $db->execute("UPDATE nn SET id='' WHERE id=1");
# ok 5
ok($res->{type} eq 'error', "NOT NULL: UPDATE to empty string fails");
# ok 6
ok(($res->{message} =~ /NOT NULL/) ? 1 : 0, "NOT NULL: UPDATE error message mentions NOT NULL");

# Valid UPDATE does not affect NOT NULL checking
$res = $db->execute("UPDATE nn SET name='AliceNew' WHERE id=1");
# ok 7
ok($res->{type} eq 'ok', "NOT NULL: valid UPDATE ok");

###############################################################################
# DEFAULT: applied when column is omitted in INSERT
###############################################################################
$db->execute("CREATE TABLE df (
    id     INT          NOT NULL,
    status VARCHAR(10)  DEFAULT 'active',
    score  INT          DEFAULT 0
)");

$res = $db->execute("INSERT INTO df (id) VALUES (1)");
# ok 8
ok($res->{type} eq 'ok', "DEFAULT: INSERT omitting defaulted cols ok");

$res = $db->execute("SELECT status, score FROM df WHERE id=1");
# ok 9
is($res->{data}[0]{status}, 'active', "DEFAULT: status='active' applied");
# ok 10
is($res->{data}[0]{score}+0, 0, "DEFAULT: score=0 applied");

# Explicit value overrides DEFAULT
$res = $db->execute("INSERT INTO df (id,status,score) VALUES (2,'inactive',99)");
$res = $db->execute("SELECT status, score FROM df WHERE id=2");
# ok 11
is($res->{data}[0]{status}, 'inactive', "DEFAULT: explicit value overrides default");
# ok 12
is($res->{data}[0]{score}+0, 99, "DEFAULT: explicit score overrides default");

# Multiple rows with defaults
$db->execute("INSERT INTO df (id) VALUES (3)");
$db->execute("INSERT INTO df (id) VALUES (4)");
$res = $db->execute("SELECT COUNT(*) AS n FROM df WHERE status='active'");
# ok 13
is($res->{data}[0]{n}+0, 3, "DEFAULT: 3 rows have default status=active");

###############################################################################
# CHECK: evaluated on INSERT (violation)
###############################################################################
$db->execute("CREATE TABLE ck (id INT NOT NULL, salary INT CHECK (salary >= 0))");

$res = $db->execute("INSERT INTO ck (id,salary) VALUES (1,50000)");
# ok 14
ok($res->{type} eq 'ok', "CHECK: valid INSERT ok");

$res = $db->execute("INSERT INTO ck (id,salary) VALUES (2,-100)");
# ok 15
ok($res->{type} eq 'error', "CHECK: INSERT with negative salary fails");
# ok 16
ok(($res->{message} =~ /CHECK/) ? 1 : 0, "CHECK: error message mentions CHECK");

###############################################################################
# CHECK: evaluated on UPDATE (violation)
###############################################################################
$res = $db->execute("UPDATE ck SET salary=-9999 WHERE id=1");
# ok 17
ok($res->{type} eq 'error', "CHECK: UPDATE with negative salary fails");
# ok 18
ok(($res->{message} =~ /CHECK/) ? 1 : 0, "CHECK: UPDATE error message mentions CHECK");

###############################################################################
# PRIMARY KEY: implies NOT NULL and an auto-created UNIQUE index <col>_pk
###############################################################################
$db->execute("CREATE TABLE pk (id INT PRIMARY KEY, name VARCHAR(20))");

$res = $db->execute("INSERT INTO pk (id,name) VALUES (1,'Alice')");
# ok 19
ok($res->{type} eq 'ok', "PRIMARY KEY: valid INSERT ok");

# PRIMARY KEY implies NOT NULL
$res = $db->execute("INSERT INTO pk (name) VALUES ('Bob')");
# ok 20
ok($res->{type} eq 'error', "PRIMARY KEY: omitting PK column fails (NOT NULL)");

# PRIMARY KEY enforces uniqueness through the auto-created index
$res = $db->execute("INSERT INTO pk (id,name) VALUES (1,'Dup')");
# ok 21
ok($res->{type} eq 'error', "PRIMARY KEY: duplicate rejected without explicit UNIQUE INDEX");

# The auto-created index is named after the column
my $pk_idx = $db->list_indexes('pk');
# ok 22
ok((grep { $_->{name} eq 'id_pk' && $_->{unique} && $_->{col} eq 'id' } @$pk_idx),
   "PRIMARY KEY: auto-created UNIQUE index is named id_pk");
# ok 23
ok(($res->{message} =~ /UNIQUE/) ? 1 : 0, "PRIMARY KEY: error mentions UNIQUE");

###############################################################################
# PRIMARY KEY: schema records PK column name
###############################################################################
# Verify via DESCRIBE
$res = $db->execute("DESCRIBE pk");
# ok 24
ok($res->{type} eq 'describe', "PRIMARY KEY: DESCRIBE works on PK table");

###############################################################################
# UNIQUE via CREATE UNIQUE INDEX: INSERT enforcement
###############################################################################
$db->execute("CREATE TABLE uq (id INT, email VARCHAR(40))");
$db->execute("CREATE UNIQUE INDEX uq_email ON uq (email)");

{ my $e='a@b.com'; $db->execute("INSERT INTO uq (id,email) VALUES (1,'$e')"); }
{ my $e='c@d.com'; $db->execute("INSERT INTO uq (id,email) VALUES (2,'$e')"); }

{ my $e='a@b.com'; $res = $db->execute("INSERT INTO uq (id,email) VALUES (3,'$e')"); }
# ok 25
ok($res->{type} eq 'error', "UNIQUE INDEX: duplicate email INSERT rejected");
# ok 26
ok(($res->{message} =~ /UNIQUE/) ? 1 : 0, "UNIQUE INDEX: error message mentions UNIQUE");

###############################################################################
# UNIQUE via CREATE UNIQUE INDEX: UPDATE enforcement
###############################################################################
{ my $e='a@b.com'; $res = $db->execute("UPDATE uq SET email='$e' WHERE id=2"); }
# ok 27
ok($res->{type} eq 'error', "UNIQUE INDEX: UPDATE to duplicate email rejected");

# Self-update (same value) should be allowed
{ my $e='a@b.com'; $res = $db->execute("UPDATE uq SET email='$e' WHERE id=1"); }
# ok 28
ok($res->{type} eq 'ok', "UNIQUE INDEX: self-update (same value) allowed");

###############################################################################
# Multiple constraints on one table
###############################################################################
$db->execute("CREATE TABLE multi (
    id     INT         NOT NULL,
    name   VARCHAR(20) NOT NULL,
    age    INT         DEFAULT 0 CHECK (age >= 0),
    grade  VARCHAR(5)  DEFAULT 'C'
)");
$db->execute("CREATE UNIQUE INDEX multi_id ON multi (id)");

# All constraints satisfied
$res = $db->execute("INSERT INTO multi (id,name,age,grade) VALUES (1,'Alice',25,'A')");
# ok 29
ok($res->{type} eq 'ok', "multi-constraint: valid INSERT ok");

# NOT NULL violation (name omitted)
$res = $db->execute("INSERT INTO multi (id,age) VALUES (2,20)");
# ok 30
ok($res->{type} eq 'error', "multi-constraint: NOT NULL on name fails");

# CHECK violation (age < 0)
$res = $db->execute("INSERT INTO multi (id,name,age) VALUES (3,'Bob',-5)");
# ok 31
ok($res->{type} eq 'error', "multi-constraint: CHECK on age fails");

# UNIQUE violation
$res = $db->execute("INSERT INTO multi (id,name) VALUES (1,'Carol')");
# ok 32
ok($res->{type} eq 'error', "multi-constraint: UNIQUE on id fails");

# DEFAULT applied when omitted
$res = $db->execute("INSERT INTO multi (id,name) VALUES (4,'Dave')");
$res = $db->execute("SELECT age, grade FROM multi WHERE id=4");
# ok 33
is($res->{data}[0]{age}+0, 0,   "multi-constraint: age DEFAULT=0");
# ok 34
is($res->{data}[0]{grade}, 'C', "multi-constraint: grade DEFAULT='C'");

###############################################################################
# NOT NULL with various data types
###############################################################################
$db->execute("CREATE TABLE nn_types (
    i INT     NOT NULL,
    f FLOAT   NOT NULL,
    v VARCHAR(10) NOT NULL,
    c CHAR(5) NOT NULL,
    d DATE    NOT NULL
)");

$res = $db->execute("INSERT INTO nn_types (i,f,v,c,d) VALUES (1,1.5,'hi','AB','2024-01-01')");
# ok 35
ok($res->{type} eq 'ok', "NOT NULL all types: valid INSERT ok");

$res = $db->execute("INSERT INTO nn_types (f,v,c,d) VALUES (1.5,'hi','AB','2024-01-01')");
# ok 36
ok($res->{type} eq 'error', "NOT NULL INT: omit fails");

$res = $db->execute("INSERT INTO nn_types (i,v,c,d) VALUES (2,'hi','AB','2024-01-01')");
# ok 37
ok($res->{type} eq 'error', "NOT NULL FLOAT: omit fails");

###############################################################################
# DEFAULT: numeric zero vs empty
###############################################################################
$db->execute("CREATE TABLE dfnum (id INT, x INT DEFAULT 0, y FLOAT DEFAULT 0)");
$db->execute("INSERT INTO dfnum (id) VALUES (1)");
$res = $db->execute("SELECT x, y FROM dfnum WHERE id=1");
# ok 38
is($res->{data}[0]{x}+0, 0, "DEFAULT INT 0 applied");
# ok 39
is($res->{data}[0]{y}+0, 0, "DEFAULT FLOAT 0 applied");

###############################################################################
# SHOW DATABASES / SHOW TABLES / DESCRIBE
###############################################################################
my @dbs = $db->list_databases;
# ok 40
ok(scalar(grep { $_ eq 'ctest' } @dbs), "SHOW DATABASES: ctest present");

$res = $db->execute("SHOW DATABASES");
# ok 41
ok($res->{type} eq 'list', "SHOW DATABASES returns list type");
# ok 42
ok(scalar(grep { $_ eq 'ctest' } @{$res->{data}}), "SHOW DATABASES data: ctest present");

$res = $db->execute("SHOW TABLES");
# ok 43
ok($res->{type} eq 'list', "SHOW TABLES returns list type");
# ok 44
ok(scalar(grep { $_ eq 'nn' } @{$res->{data}}), "SHOW TABLES data: nn present");

$res = $db->execute("DESCRIBE nn");
# ok 45
ok($res->{type} eq 'describe', "DESCRIBE returns describe type");
# ok 46
ok(ref $res->{data} eq 'ARRAY' && @{$res->{data}} == 2, "DESCRIBE nn: 2 columns");
# ok 47
is($res->{data}[0]{name}, 'id', "DESCRIBE nn: first col is id");

###############################################################################
# Cleanup
###############################################################################
###############################################################################
# Emit the plan.  The count is taken from the assertions that actually ran,
# so it can never drift out of step with the body the way the former
# hard-coded "1..N" line could.  The ok() lines are buffered in @OUT purely
# so that the plan can still be printed first: a leading plan is what every
# Test::Harness understands, including the one shipped with Perl 5.005_03.
###############################################################################
$DONE = 1;
print "1..$T\n", @OUT;

exit($FAIL ? 1 : 0);

# If the body dies before the plan is emitted, flush whatever did run and
# append one failing assertion, so the harness is handed a complete and
# definitely-failing stream instead of no plan at all.
END {
    unless ($DONE) {
        print '1..' . ($T + 1) . "\n", @OUT;
        print 'not ok ' . ($T + 1) . " - test script aborted before completion\n";
    }
}
