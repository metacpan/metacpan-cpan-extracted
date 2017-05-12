#!/usr/local/bin/perl -w

use App::Options (
    options => [qw(dbdriver dbclass dbhost dbname dbuser dbpass)],
    option => {
        dbclass  => { default => "App::Repository::MySQL", },
        dbdriver => { default => "mysql", },
        dbhost   => { default => "localhost", },
        dbname   => { default => "test", },
        dbuser   => { default => "", },
        dbpass   => { default => "", },
    },
);

use Test::More qw(no_plan);
use lib "../App-Context/lib";
use lib "../../App-Context/lib";
use lib "lib";
use lib "../lib";

use App;
use App::Repository;
use strict;

if (!$App::options{dbuser}) {
    ok(1, "No dbuser given. Tests assumed OK. (add dbuser=xxx and dbpass=yyy to app.conf in 't' directory)");
    exit(0);
}

my $context = App->context(
    conf_file => "",
    conf => {
        Repository => {
            default => {
                class => $App::options{dbclass},
                dbdriver => $App::options{dbdriver},
                dbhost => $App::options{dbhost},
                dbname => $App::options{dbname},
                dbuser => $App::options{dbuser},
                dbpass => $App::options{dbpass},
                table => {
                    test_person => {
                        primary_key => ["person_id"],
                        column => {
                            gender => {
                                alias => "gnd",
                            },
                        },
                    },
                },
            },
        },
    },
);

my $rep = $context->repository();

#cheating... I know its a DBI, but I have to set up the test somehow
my $dbh     = $rep->{dbh};
eval { $dbh->do("drop table test_person"); };
my $ddl     = <<EOF;
create table test_person (
    person_id          integer      not null auto_increment primary key,
    first_name         varchar(99)  null,
    last_name          varchar(99)  null,
    address            varchar(99)  null,
    city               varchar(99)  null,
    state              varchar(99)  null,
    zip                varchar(10)  null,
    country            char(2)      null,
    home_phone         varchar(99)  null,
    work_phone         varchar(99)  null,
    email_address      varchar(99)  null,
    gender             char(1)      null,
    birth_dt           date         null,
    age                integer      null,
    index person_ie1 (last_name, first_name)
)
EOF
$dbh->do($ddl);

my $columns = [ "person_id", "age", "first_name", "gender", "state", "birth_dt" ];
my $rows = [
    [ 1, 39, "stephen",   "M", "GA", "1962-01-01"],
    [ 2, 37, "susan",     "F", "GA", "1964-08-08"],
    [ 3,  6, "maryalice", "F", "GA", "1996-07-07"],
    [ 4,  3, "paul",      "M", "GA", "1999-04-04"],
    [ 5,  1, "christine", "F", "GA", "2000-05-05"],
    [ 6, 45, "tim",       "M", "GA", "1956-02-02"],
    [ 7, 39, "keith",     "M", "GA", "1962-03-03"],
];

#$App::aspect = 1;
#eval {
#    $rep->set_rows("test_person", undef, $columns, $rows);
#};
#ok(!$@, "set_rows() [test_person]");

sub check_select {
    my ($sql, $expected_rows, $debug) = @_;

    my ($rows, $reprows);
    eval {
        $rows = $dbh->selectall_arrayref($sql);
    };
    is($@,"","sql ok");
    if ($debug) {
        print $sql;
        print "ROWS [", ($#$rows + 1), "]\n";
        foreach my $row (@$rows) {
            print "ROW [", join("|", @$row), "]\n";
        }
    }

    if (defined $expected_rows) {
        is(($#$rows + 1), $expected_rows, "num rows $expected_rows");
    }
}

# &test_get_rows($expect_sql,0,"_mk_select_joined_sql(): 1 col, no params","test_person",{},"age");
sub test_get_rows {
    my $expected_sql = shift;
    my $expected_rows = shift;
    my $msg = shift;
    my $sql = $rep->_mk_select_joined_sql(@_);
    is($sql,$expected_sql,"$msg - sql");

    my ($rows, $reprows);
    eval {
        $rows = $dbh->selectall_arrayref($sql);
    };
    is($@,"","$msg - sql ok");

    if (defined $expected_rows) {
        is(($#$rows + 1), $expected_rows, "$msg - num rows $expected_rows");
    }

    eval {
        $reprows = $rep->get_rows(@_);
    };
    is($@,"","$msg - get_rows() ok");
    is_deeply($reprows,$rows,"$msg - data same");
    return($sql);
}

my ($sql, $expect_sql);
###########################################################################
# RAW (SINGLE-TABLE) SELECT SQL-GENERATION TESTS
###########################################################################

$expect_sql = <<EOF;
select
   age
from test_person
EOF
$sql = $rep->_mk_select_sql("test_person",{},"age");
is($sql, $expect_sql, "_mk_select_sql(): 1 col, no params");
&check_select($sql,0);
$sql = $rep->_mk_select_sql("test_person",{},["age"]);
is($sql, $expect_sql, "_mk_select_sql(): 1 col as array, no params");
&check_select($sql,0);

$expect_sql = <<EOF;
select
   age
from test_person
where person_id = 1
EOF
$sql = $rep->_mk_select_sql("test_person",1,"age");
is($sql, $expect_sql, "_mk_select_sql(): key");
&check_select($sql,0);
$sql = $rep->_mk_select_sql("test_person",1,["age"]);
is($sql, $expect_sql, "_mk_select_sql(): key (again)");
&check_select($sql,0);

$expect_sql = <<EOF;
select
   age
from test_person
where person_id is null
EOF
$sql = $rep->_mk_select_sql("test_person",undef,"age");
is($sql, $expect_sql, "_mk_select_sql(): by key (bind vars)");
&check_select($sql,0);

$expect_sql = <<EOF;
select
   age
from test_person
where age = 37
EOF
$sql = $rep->_mk_select_sql("test_person",{age => 37},"age");
is($sql, $expect_sql, "_mk_select_sql(): param");
&check_select($sql,0);

$expect_sql = <<EOF;
select
   age
from test_person
where gender = 'M'
EOF
$sql = $rep->_mk_select_sql("test_person",{gender => "M"},"age");
is($sql, $expect_sql, "_mk_select_sql(): non-selected param");
&check_select($sql,0);

$expect_sql = <<EOF;
select
   first_name
from test_person
where first_name = 'stephen'
  and age = 37
  and birth_dt = '1962-01-01'
EOF
$sql = $rep->_mk_select_sql("test_person",{
        "_order" => [ "first_name", "age", "birth_dt", ],
        "first_name" => "stephen",
        "age" => "37",
        "birth_dt" => "1962-01-01",
    },["first_name"]);
is($sql, $expect_sql, "_mk_select_sql(): params plain");
&check_select($sql,0);

$expect_sql = <<EOF;
select
   first_name
from test_person
where first_name is null
  and age is null
  and birth_dt is null
EOF
$sql = $rep->_mk_select_sql("test_person",{
        "_order" => [ "first_name", "age", "birth_dt", ],
        "first_name" => undef,
        "age" => undef,
        "birth_dt" => undef,
    },["first_name"]);
is($sql, $expect_sql, "_mk_select_sql(): params (bind vars)");
&check_select($sql,0);

$expect_sql = <<EOF;
select
   first_name
from test_person
where first_name in ('stephen','paul')
  and age in (37,39)
  and birth_dt in ('1962-01-01','1963-12-31')
EOF
$sql = $rep->_mk_select_sql("test_person",{
        "_order" => [ "first_name", "age", "birth_dt", ],
        "first_name" => "stephen,paul",
        "age" => "37,39",
        "birth_dt" => "1962-01-01,1963-12-31",
    },["first_name"]);
is($sql, $expect_sql, "_mk_select_sql(): params auto_in");
&check_select($sql,0);

$expect_sql = <<EOF;
select
   first_name
from test_person
where first_name = 'stephen'
  and age = 37
  and birth_dt = '1962-01-01'
EOF
$sql = $rep->_mk_select_sql("test_person",{
        "_order" => [ "first_name.eq", "age.eq", "birth_dt.eq", ],
        "first_name.eq" => "stephen",
        "age.eq" => "37",
        "birth_dt.eq" => "1962-01-01",
    },["first_name"]);
is($sql, $expect_sql, "_mk_select_sql(): param.eq");
&check_select($sql,0);

$expect_sql = <<EOF;
select
   first_name
from test_person
where first_name = 'stephen,paul'
  and age in (37,39)
  and birth_dt = '1962-01-01,1963-12-31'
EOF
$sql = $rep->_mk_select_sql("test_person",{
        "_order" => [ "first_name.eq", "age", "birth_dt.eq", ],
        "first_name.eq" => "stephen,paul",
        "age" => "37,39",
        "birth_dt.eq" => "1962-01-01,1963-12-31",
    },["first_name"]);
is($sql, $expect_sql, "_mk_select_sql(): param.eq => in");
&check_select($sql,0);
$sql = $rep->_mk_select_sql("test_person",{
        "_order" => [ "first_name", "age", "birth_dt", ],
        "first_name" => "==stephen,paul",
        "age" => "=37,39",
        "birth_dt" => "==1962-01-01,1963-12-31",
    },["first_name"]);
is($sql, $expect_sql, "_mk_select_sql(): param.eq => in (inferred)");
&check_select($sql,0);

$expect_sql = <<EOF;
select
   first_name
from test_person
where first_name = 'stephen'
  and age = 37
  and birth_dt = '1962-01-01'
EOF
$sql = $rep->_mk_select_sql("test_person",{
        "_order" => [ "first_name.in", "age.in", "birth_dt.in", ],
        "first_name.in" => "stephen",
        "age.in" => "37",
        "birth_dt.in" => "1962-01-01",
    },["first_name"]);
is($sql, $expect_sql, "_mk_select_sql(): param.in => eq");
&check_select($sql,0);

$expect_sql = <<EOF;
select
   first_name
from test_person
where first_name in ('stephen','paul')
  and age in (37,39)
  and birth_dt in ('1962-01-01','1963-12-31')
EOF
$sql = $rep->_mk_select_sql("test_person",{
        "_order" => [ "first_name.in", "age.in", "birth_dt.in", ],
        "first_name.in" => "stephen,paul",
        "age.in" => "37,39",
        "birth_dt.in" => "1962-01-01,1963-12-31",
    },["first_name"]);
is($sql, $expect_sql, "_mk_select_sql(): param.in");
&check_select($sql,0);

$expect_sql = <<EOF;
select
   first_name
from test_person
where first_name != 'stephen'
  and age != 37
  and birth_dt != '1962-01-01'
EOF
$sql = $rep->_mk_select_sql("test_person",{
        "_order" => [ "first_name.ne", "age.ne", "birth_dt.ne", ],
        "first_name.ne" => "stephen",
        "age.ne" => "37",
        "birth_dt.ne" => "1962-01-01",
    },["first_name"]);
is($sql, $expect_sql, "_mk_select_sql(): param.ne");
&check_select($sql,0);

$expect_sql = <<EOF;
select
   first_name
from test_person
where first_name >= 'stephen'
  and age >= 37
  and birth_dt >= '1962-01-01'
EOF
$sql = $rep->_mk_select_sql("test_person",{
        "_order" => [ "first_name.ge", "age.ge", "birth_dt.ge", ],
        "first_name.ge" => "stephen",
        "age.ge" => "37",
        "birth_dt.ge" => "1962-01-01",
    },["first_name"]);
is($sql, $expect_sql, "_mk_select_sql(): param.ge");
&check_select($sql,0);

$expect_sql = <<EOF;
select
   first_name
from test_person
where first_name > 'stephen'
  and age > 37
  and birth_dt > '1962-01-01'
EOF
$sql = $rep->_mk_select_sql("test_person",{
        "_order" => [ "first_name.gt", "age.gt", "birth_dt.gt", ],
        "first_name.gt" => "stephen",
        "age.gt" => "37",
        "birth_dt.gt" => "1962-01-01",
    },["first_name"]);
is($sql, $expect_sql, "_mk_select_sql(): param.gt");
&check_select($sql,0);

$expect_sql = <<EOF;
select
   first_name
from test_person
where first_name <= 'stephen'
  and age <= 37
  and birth_dt <= '1962-01-01'
EOF
$sql = $rep->_mk_select_sql("test_person",{
        "_order" => [ "first_name.le", "age.le", "birth_dt.le", ],
        "first_name.le" => "stephen",
        "age.le" => "37",
        "birth_dt.le" => "1962-01-01",
    },["first_name"]);
is($sql, $expect_sql, "_mk_select_sql(): param.le");
&check_select($sql,0);

$expect_sql = <<EOF;
select
   first_name
from test_person
where first_name < 'stephen'
  and age < 37
  and birth_dt < '1962-01-01'
EOF
$sql = $rep->_mk_select_sql("test_person",{
        "_order" => [ "first_name.lt", "age.lt", "birth_dt.lt", ],
        "first_name.lt" => "stephen",
        "age.lt" => "37",
        "birth_dt.lt" => "1962-01-01",
    },["first_name"]);
is($sql, $expect_sql, "_mk_select_sql(): param.lt");
&check_select($sql,0);

$expect_sql = <<EOF;
select
   first_name
from test_person
where first_name like '%s%'
  and age like '%3%'
  and birth_dt like '%1962%'
EOF
$sql = $rep->_mk_select_sql("test_person",{
        "_order" => [ "first_name.contains", "age.contains", "birth_dt.contains", ],
        "first_name.contains" => "s",
        "age.contains" => "3",
        "birth_dt.contains" => "1962",
    },["first_name"]);
is($sql, $expect_sql, "_mk_select_sql(): param.contains");
&check_select($sql,0);
$sql = $rep->_mk_select_sql("test_person",{
        "_order" => [ "first_name", "age", "birth_dt", ],
        "first_name" => "=~s",
        "age" => "=~3",
        "birth_dt" => "~1962",
    },["first_name"]);
is($sql, $expect_sql, "_mk_select_sql(): param.contains (inferred)");
&check_select($sql,0);

$expect_sql = <<EOF;
select
   first_name
from test_person
where first_name not like '%s%'
  and age not like '%3%'
  and birth_dt not like '%1962%'
EOF
$sql = $rep->_mk_select_sql("test_person",{
        "_order" => [ "first_name.not_contains", "age.not_contains", "birth_dt.not_contains", ],
        "first_name.not_contains" => "s",
        "age.not_contains" => "3",
        "birth_dt.not_contains" => "1962",
    },["first_name"]);
is($sql, $expect_sql, "_mk_select_sql(): param.contains");
&check_select($sql,0);
$sql = $rep->_mk_select_sql("test_person",{
        "_order" => [ "first_name", "age", "birth_dt", ],
        "first_name" => "!~s",
        "age" => "!~3",
        "birth_dt" => "!~1962",
    },["first_name"]);
is($sql, $expect_sql, "_mk_select_sql(): param.not_contains (inferred)");
&check_select($sql,0);

$expect_sql = <<EOF;
select
   first_name
from test_person
where first_name like '%s%e_'
  and age like '%3'
  and birth_dt like '1962\\_%'
EOF
$sql = $rep->_mk_select_sql("test_person",{
        "_order" => [ "first_name.matches", "age.matches", "birth_dt.matches", ],
        "first_name.matches" => "*s*e?",
        "age.matches" => "*3",
        "birth_dt.matches" => "1962_*",
    },["first_name"]);
is($sql, $expect_sql, "_mk_select_sql(): param.matches");
&check_select($sql,0);
$sql = $rep->_mk_select_sql("test_person",{
        "_order" => [ "first_name", "age", "birth_dt", ],
        "first_name" => "*s*e?",
        "age" => "*3",
        "birth_dt" => "1962_*",
    },["first_name"]);
is($sql, $expect_sql, "_mk_select_sql(): param.matches (inferred)");
&check_select($sql,0);

$sql = $rep->_mk_select_sql("test_person",{
        "_order" => [ "first_name", "age", "birth_dt", ],
        "first_name" => "*s*e?",
        "age" => "*3",
        "birth_dt" => "1962_*",
    },["first_name"]);
is($sql, $expect_sql, "_mk_select_sql(): param.matches (inferred)");
&check_select($sql,0);

$expect_sql = <<EOF;
select
   first_name
from test_person
where first_name not like '%s%'
  and age not like '%3'
  and birth_dt not like '1962%'
EOF
$sql = $rep->_mk_select_sql("test_person",{
        "_order" => [ "first_name.not_matches", "age.not_matches", "birth_dt.not_matches", ],
        "first_name.not_matches" => "*s*",
        "age.not_matches" => "*3",
        "birth_dt.not_matches" => "1962*",
    },["first_name"]);
is($sql, $expect_sql, "_mk_select_sql(): param.not_matches");
&check_select($sql,0);

# this doesn't work yet, but that's ok
#$sql = $rep->_mk_select_sql("test_person",{
#        "_order" => [ "first_name", "age", "birth_dt", ],
#        "first_name" => "!*s*",
#        "age" => "!*3",
#        "birth_dt" => "!1962*",
#    },["first_name"]);
#is($sql, $expect_sql, "_mk_select_sql(): param.not_matches (inferred)");
#&check_select($sql,0);

$expect_sql = <<EOF;
select
   first_name,
   last_name,
   age
from test_person
where age >= 37
limit 1
EOF
$sql = $rep->_mk_select_sql("test_person",{"age.ge" => 37},["first_name","last_name","age"],{startrow => 1, endrow => 1});
is($sql, $expect_sql, "_mk_select_sql(): cols, endrow");
&check_select($sql,0);

$expect_sql = <<EOF;
select
   first_name,
   last_name,
   city,
   state,
   age
from test_person
order by
   last_name asc,
   city,
   address,
   gender desc,
   first_name
EOF
$sql = $rep->_mk_select_sql("test_person",{},["first_name","last_name","city","state","age"],
    {ordercols=>["last_name","city","address","gender","first_name"],
     directions=>{last_name=>"ASC",city=>"",address=>undef,gender=>"Desc"}});
is($sql, $expect_sql, "_mk_select_sql(): ordercols, directions");
&check_select($sql,0);

$expect_sql = <<EOF;
select
   first_name,
   last_name,
   city,
   state,
   age
from test_person
where age in (14,15,16,17,18)
EOF
$sql = $rep->_mk_select_sql("test_person",
                            {"age.verbatim" => "age in (14,15,16,17,18)"},
                            ["first_name","last_name","city","state","age"]);
is($sql, $expect_sql, "_mk_select_sql(): verbatim");
&check_select($sql,0);

###########################################################################
# NULL CONDITIONS (AND "IN")
###########################################################################

$expect_sql = <<EOF;
select
   gender
from test_person
where age is null
EOF
$sql = $rep->_mk_select_sql("test_person", { age => "NULL", }, ["gender"]);
is($sql, $expect_sql, "_mk_select_sql(): is null (by 'NULL')");
&check_select($sql,0);
$sql = $rep->_mk_select_sql("test_person", { age => undef, }, ["gender"]);
is($sql, $expect_sql, "_mk_select_sql(): is null (by undef)");
&check_select($sql,0);

$expect_sql = <<EOF;
select
   gender
from test_person
where age is not null
EOF
$sql = $rep->_mk_select_sql("test_person", { age => "!NULL", }, ["gender"]);
is($sql, $expect_sql, "_mk_select_sql(): is not null (by '!NULL')");
&check_select($sql,0);
$sql = $rep->_mk_select_sql("test_person", { "age.ne" => undef, }, ["gender"]);
is($sql, $expect_sql, "_mk_select_sql(): is not null (by .ne undef)");
&check_select($sql,0);

$expect_sql = <<EOF;
select
   gender
from test_person
where first_name is not null
EOF
$sql = $rep->_mk_select_sql("test_person", { first_name => "!NULL", }, ["gender"]);
is($sql, $expect_sql, "_mk_select_sql(): is not null (by '!NULL')");
&check_select($sql,0);
$sql = $rep->_mk_select_sql("test_person", { "first_name.ne" => undef, }, ["gender"]);
is($sql, $expect_sql, "_mk_select_sql(): is not null (by .ne undef)");
&check_select($sql,0);

$expect_sql = <<EOF;
select
   gender
from test_person
where (first_name not in ('stephen','keith') and first_name is not null)
EOF
$sql = $rep->_mk_select_sql("test_person", { first_name => "!stephen,keith,NULL", }, ["gender"]);
is($sql, $expect_sql, "_mk_select_sql(): not in and not null (by '!stephen,keith,NULL')");
&check_select($sql,0);
$sql = $rep->_mk_select_sql("test_person", { "first_name.not_in" => "stephen,keith,NULL", }, ["gender"]);
is($sql, $expect_sql, "_mk_select_sql(): is not null (by .not_in 'stephen,keith,NULL')");
&check_select($sql,0);

$expect_sql = <<'EOF';
select
   first_name
from test_person
where first_name like '%\'%'
  and birth_dt like '%\\\'_'
EOF
#print "[$expect_sql]\n";
$sql = $rep->_mk_select_sql("test_person",{
        "_order" => [ "first_name.contains", "birth_dt.matches", ],
        "first_name.contains" => "'",
        "birth_dt.matches" => "*\\'?",
    },["first_name"]);
is($sql, $expect_sql, "_mk_select_sql(): param.contains (proper quoting of ' and \\' required)");
&check_select($sql,0);

exit(0);

$expect_sql = <<EOF;
select
   gender
from test_person
where first_name is not null
EOF
$sql = $rep->_mk_select_sql("test_person", { age => "!NULL", }, ["gender"]);
is($sql, $expect_sql, "_mk_select_sql(): is not null (by '!NULL')");
&check_select($sql,0);
$sql = $rep->_mk_select_sql("test_person", { "age.ne" => undef, }, ["gender"]);
is($sql, $expect_sql, "_mk_select_sql(): is not null (by .ne undef)");
&check_select($sql,0);

$expect_sql = <<EOF;
select
   first_name,
   last_name
from test_person
where (age in (14,15,16) or age is null)
EOF
$sql = $rep->_mk_select_sql("test_person",
                            {"age" => "14,15,16,NULL"},
                            ["first_name","last_name"]);
is($sql, $expect_sql, "_mk_select_sql(): ,NULL");
&check_select($sql,0);

$expect_sql = <<EOF;
select
   first_name,
   last_name
from test_person
where (age in (14,15,16) or age is null)
EOF
$sql = $rep->_mk_select_sql("test_person",
                            {"age" => "NULL,14,15,16"},
                            ["first_name","last_name"]);
is($sql, $expect_sql, "_mk_select_sql(): NULL,");
&check_select($sql,0);

$expect_sql = <<EOF;
select
   first_name,
   last_name
from test_person
where (age in (14,15,16) or age is null)
EOF
$sql = $rep->_mk_select_sql("test_person",
                            {"age" => "14,15,NULL,16"},
                            ["first_name","last_name"]);
is($sql, $expect_sql, "_mk_select_sql(): ,NULL,");
&check_select($sql,0);

$expect_sql = <<EOF;
select
   first_name,
   last_name
from test_person
where age is null
EOF
$sql = $rep->_mk_select_sql("test_person",
                            {"age" => "NULL"},
                            ["first_name","last_name"]);
is($sql, $expect_sql, "_mk_select_sql(): NULL");
&check_select($sql,0);

$expect_sql = <<EOF;
select
   first_name,
   last_name
from test_person
where age is null
EOF
$sql = $rep->_mk_select_sql("test_person",
                            {"age" => undef},
                            ["first_name","last_name"]);
is($sql, $expect_sql, "_mk_select_sql(): undef (NULL)");
&check_select($sql,0);

$expect_sql = <<EOF;
select
   first_name,
   last_name
from test_person
where first_name = ''
EOF
$sql = $rep->_mk_select_sql("test_person",
                            {"first_name" => ""},
                            ["first_name","last_name"]);
is($sql, $expect_sql, "_mk_select_sql(): \"\" (use literal as string)");
&check_select($sql,0);

$expect_sql = <<EOF;
select
   first_name,
   last_name
from test_person
EOF
$sql = $rep->_mk_select_sql("test_person",
                            {"age" => ""},
                            ["first_name","last_name"]);
is($sql, $expect_sql, "_mk_select_sql(): \"\" (ALL)");
&check_select($sql,0);

$expect_sql = <<EOF;
select
   first_name,
   last_name
from test_person
EOF
$sql = $rep->_mk_select_sql("test_person",
                            {"age" => "ALL"},
                            ["first_name","last_name"]);
is($sql, $expect_sql, "_mk_select_sql(): explicit ALL adds nothing to the where clause");
&check_select($sql,0);

$expect_sql = <<EOF;
select distinct
   gender
from test_person
EOF
$sql = $rep->_mk_select_sql("test_person",
                            {},
                            ["gender"],
                            {distinct => 1});
is($sql, $expect_sql, "_mk_select_sql(): distinct");
&check_select($sql,0);

###########################################################################
# NEW REPOPS CONDITIONS
###########################################################################

$expect_sql = <<EOF;
select
   gender
from test_person
where age is null
EOF
$sql = $rep->_mk_select_sql("test_person", { age => "NULL", }, ["gender"]);
is($sql, $expect_sql, "_mk_select_sql(): is null (by 'NULL')");
&check_select($sql,0);
$sql = $rep->_mk_select_sql("test_person", { age => undef, }, ["gender"]);
is($sql, $expect_sql, "_mk_select_sql(): is null (by undef)");
&check_select($sql,0);
exit(0);   # XXX REMOVE EXIT HERE XXX

###########################################################################
# LITERAL EXPRESSIONS
###########################################################################

$expect_sql = <<EOF;
select
   t1.gender gnd,
   max(age) max_age_
from
   test_person t1
group by
   gnd
order by
   gnd
EOF
&test_get_rows($expect_sql, 0, "_mk_select_joined_sql(): literal aggregation function",
    "test_person",
    {},
    ["gender","max(age)"],
    { group_by => ["gender"], order_by => ["gender"] });

$expect_sql = <<EOF;
select
   t1.gender gnd,
   2*age _2_age
from
   test_person t1
EOF
&test_get_rows($expect_sql, 0, "_mk_select_joined_sql(): literal aggregation function",
    "test_person",
    {},
    ["gender","2*age"]);

###########################################################################
# EXCEPTIONS
###########################################################################

{
    my ($rows, $row);
    open(SAVE, ">&STDERR");
    open(STDERR, "/dev/null");

    $rows = [];
    eval {
        $rows = $rep->get_rows("table_y", {}, ["x"]);
    };
    ok($@ =~ /fail/, "get_rows(): bad SQL causes exception");

    $rows = [];
    eval {
        $rows = $rep->get_row("table_y", {}, ["x"]);
    };
    ok($@ =~ /fail/, "get_row(): bad SQL causes exception");

    $rep->insert("test_person",["person_id","last_name","first_name"],[1,"Stephen","Adkins"]);

    $rep->_disconnect();
    $rows = [];
    eval {
        $rows = $rep->get_rows("test_person", {}, ["person_id"]);
    };
    ok($#$rows == 0, "get_rows(): reconnect because rep was _disconnect()ed");

    $rep->{dbh}{mysql_auto_reconnect} = 0;
    $rep->{dbh}->disconnect();
    $rows = [];
    eval {
        $rows = $rep->get_rows("test_person", {}, ["person_id"]);
    };
    ok($#$rows == 0, "get_rows(): reconnect because dbh was disconnect()ed");

    $rep->{dbh}{mysql_auto_reconnect} = 0;
    $rep->{dbh}->disconnect();
    $row = undef;
    eval {
        $row = $rep->get_row("test_person", {person_id => 1}, ["person_id"]);
    };
    ok(defined $row && $#$row == 0, "get_row(): reconnect because dbh was disconnect()ed");

    open(STDERR, ">&SAVE");
    close(SAVE);

    $rep->delete("test_person",{person_id => 1});
}

exit(0);

###########################################################################
# JOINED (MULTI-TABLE) SELECT SQL-GENERATION TESTS
###########################################################################

$expect_sql = <<EOF;
select
   t1.age cn13
from
   test_person t1
EOF
#$App::trace = 1;
#$App::trace = 1;
&test_get_rows($expect_sql,0,"_mk_select_joined_sql(): 1 col, no params","test_person",{},"age");

exit(0);

$expect_sql = <<EOF;
select
   t1.first_name,
   t1.state,
   t1.age
from test_person
where (age in (14,15) or age > 18 or age is null)
EOF
&test_get_rows($expect_sql, 0, "_mk_select_joined_sql(): OR conditions with [] value",
    "test_person",
    {age => [14, 15, ">18", undef]},
    ["first_name","state","age"]);
$sql = $rep->_mk_select_sql("test_person",
                            {age => [14,15,">18",undef]},
                            ["first_name","state","age"]);
is($sql, $expect_sql, "_mk_select_sql(): OR conditions with [] value");
&check_select($sql,0);

$expect_sql = <<EOF;
select
   t1.first_name,
   t1.state,
   t1.age
from test_person
where age > 14
  and first_name like '%A%'
EOF
&test_get_rows($expect_sql, 0, "_mk_select_joined_sql(): square bracket [] params",
    "test_person",
    [age => ">14", first_name => "*A*"],
    ["first_name","state","age"]);
$sql = $rep->_mk_select_sql("test_person",
                            [age => ">14", first_name => "*A*"],
                            ["first_name","state","age"]);
is($sql, $expect_sql, "_mk_select_sql(): square bracket [] params");
&check_select($sql,0);

$expect_sql = <<EOF;
select
   t1.first_name,
   t1.state,
   t1.age
from test_person
where age > 14
   or not (first_name like '%A%')
   or (state in ('GA','CA') and
       age <= 2)
EOF
&test_get_rows($expect_sql, 0, "_mk_select_joined_sql(): ordercols, directions",
    "test_person",
    ["_or", age => ">14",
      ["_not", first_name => "*A*"],
      ["_and", state => "GA,CA", "age.le" => 2]],
    ["first_name","state","age"]);
$sql = $rep->_mk_select_sql("test_person",
                            [age => ">14", first_name => "*A*"],
                            ["first_name","state","age"]);
is($sql, $expect_sql, "_mk_select_sql(): verbatim");
&check_select($sql,0);

$expect_sql = <<EOF;
select
   t1.first_name,
   t1.state,
   t1.age
from test_person
where not (not(age > 14)
  and not (first_name like '%A%')
  and not (state in ('GA','CA') and
           age <= 2))
EOF
&test_get_rows($expect_sql, 0, "_mk_select_joined_sql(): ordercols, directions",
    "test_person",
    ["_not", age => ">14",
      ["_not_or", first_name => "*A*"],
      ["_not_and", state => ["GA","CA"], "age.le" => 2]],
    ["first_name","state","age"]);
$sql = $rep->_mk_select_sql("test_person",
                            [age => ">14", first_name => "*A*"],
                            ["first_name","state","age"]);
is($sql, $expect_sql, "_mk_select_sql(): verbatim");
&check_select($sql,0);

&test_get_rows($expect_sql,0,"_mk_select_joined_sql(): 1 col as array, no params","test_person",{},["age"]);

$expect_sql = <<EOF;
select
   t1.age cn13,
   t1.person_id cn0
from
   test_person t1
EOF
&test_get_rows($expect_sql,0,"_mk_select_joined_sql(): auto_extend","test_person",{},"age",{auto_extend=>1});

$expect_sql = <<EOF;
select
   t1.age cn13
from
   test_person t1
where t1.person_id = 1
EOF
&test_get_rows($expect_sql,0,"_mk_select_joined_sql(): key","test_person",1,"age");

#$expect_sql = <<EOF;
#select
#   t1.age cn13
#from
#   test_person t1
#where t1.person_id is null
#EOF
#&test_get_rows($expect_sql,0,"_mk_select_joined_sql(): by key (bind vars)","test_person",undef,"age");

$expect_sql = <<EOF;
select
   t1.age cn13
from
   test_person t1
where t1.age = 37
EOF
&test_get_rows($expect_sql,0,"_mk_select_joined_sql(): param","test_person",{age => 37},"age");

$expect_sql = <<EOF;
select
   t1.age cn13
from
   test_person t1
where t1.gender = 'M'
EOF
&test_get_rows($expect_sql,0,"_mk_select_joined_sql(): non-selected param","test_person",{gender => "M"},"age");

$expect_sql = <<EOF;
select
   t1.first_name cn1
from
   test_person t1
where t1.first_name = 'stephen'
  and t1.age = 37
  and t1.birth_dt = '1962-01-01'
EOF
&test_get_rows($expect_sql, 0, "_mk_select_joined_sql(): params plain",
    "test_person",{
        "_order" => [ "first_name", "age", "birth_dt", ],
        "first_name" => "stephen",
        "age" => "37",
        "birth_dt" => "1962-01-01",
    },["first_name"]);

$expect_sql = <<EOF;
select
   t1.first_name cn1
from
   test_person t1
where t1.first_name is null
  and t1.age is null
  and t1.birth_dt is null
EOF
&test_get_rows($expect_sql, 0, "_mk_select_joined_sql(): params (bind vars)",
    "test_person",{
        "_order" => [ "first_name", "age", "birth_dt", ],
        "first_name" => undef,
        "age" => undef,
        "birth_dt" => undef,
    },["first_name"]);

$expect_sql = <<EOF;
select
   t1.first_name cn1
from
   test_person t1
where t1.first_name in ('stephen','paul')
  and t1.age in (37,39)
  and t1.birth_dt in ('1962-01-01','1963-12-31')
EOF
&test_get_rows($expect_sql, 0, "_mk_select_joined_sql(): params auto_in",
    "test_person",{
        "_order" => [ "first_name", "age", "birth_dt", ],
        "first_name" => "stephen,paul",
        "age" => "37,39",
        "birth_dt" => "1962-01-01,1963-12-31",
    },["first_name"]);

$expect_sql = <<EOF;
select
   t1.first_name cn1
from
   test_person t1
where t1.first_name = 'stephen'
  and t1.age = 37
  and t1.birth_dt = '1962-01-01'
EOF
&test_get_rows($expect_sql, 0, "_mk_select_joined_sql(): param.eq",
    "test_person",{
        "_order" => [ "first_name.eq", "age.eq", "birth_dt.eq", ],
        "first_name.eq" => "stephen",
        "age.eq" => "37",
        "birth_dt.eq" => "1962-01-01",
    },["first_name"]);

$expect_sql = <<EOF;
select
   t1.first_name cn1
from
   test_person t1
where t1.first_name in ('stephen','paul')
  and t1.age in (37,39)
  and t1.birth_dt in ('1962-01-01','1963-12-31')
EOF
&test_get_rows($expect_sql, 0, "_mk_select_joined_sql(): param.eq => in",
    "test_person",{
        "_order" => [ "first_name.eq", "age.eq", "birth_dt.eq", ],
        "first_name.eq" => "stephen,paul",
        "age.eq" => "37,39",
        "birth_dt.eq" => "1962-01-01,1963-12-31",
    },["first_name"]);

$expect_sql = <<EOF;
select
   t1.first_name cn1
from
   test_person t1
where t1.first_name = 'stephen'
  and t1.age = 37
  and t1.birth_dt = '1962-01-01'
EOF
&test_get_rows($expect_sql, 0, "_mk_select_joined_sql(): param.in => eq",
    "test_person",{
        "_order" => [ "first_name.in", "age.in", "birth_dt.in", ],
        "first_name.in" => "stephen",
        "age.in" => "37",
        "birth_dt.in" => "1962-01-01",
    },["first_name"]);

$expect_sql = <<EOF;
select
   t1.first_name cn1
from
   test_person t1
where t1.first_name in ('stephen','paul')
  and t1.age in (37,39)
  and t1.birth_dt in ('1962-01-01','1963-12-31')
EOF
&test_get_rows($expect_sql, 0, "_mk_select_joined_sql(): param.in",
    "test_person",{
        "_order" => [ "first_name.in", "age.in", "birth_dt.in", ],
        "first_name.in" => "stephen,paul",
        "age.in" => "37,39",
        "birth_dt.in" => "1962-01-01,1963-12-31",
    },["first_name"]);

$expect_sql = <<EOF;
select
   t1.first_name cn1
from
   test_person t1
where t1.first_name != 'stephen'
  and t1.age != 37
  and t1.birth_dt != '1962-01-01'
EOF
&test_get_rows($expect_sql, 0, "_mk_select_joined_sql(): param.ne",
    "test_person",{
        "_order" => [ "first_name.ne", "age.ne", "birth_dt.ne", ],
        "first_name.ne" => "stephen",
        "age.ne" => "37",
        "birth_dt.ne" => "1962-01-01",
    },["first_name"]);

$expect_sql = <<EOF;
select
   t1.first_name cn1
from
   test_person t1
where t1.first_name >= 'stephen'
  and t1.age >= 37
  and t1.birth_dt >= '1962-01-01'
EOF
&test_get_rows($expect_sql, 0, "_mk_select_joined_sql(): param.ge",
    "test_person",{
        "_order" => [ "first_name.ge", "age.ge", "birth_dt.ge", ],
        "first_name.ge" => "stephen",
        "age.ge" => "37",
        "birth_dt.ge" => "1962-01-01",
    },["first_name"]);

$expect_sql = <<EOF;
select
   t1.first_name cn1
from
   test_person t1
where t1.first_name > 'stephen'
  and t1.age > 37
  and t1.birth_dt > '1962-01-01'
EOF
&test_get_rows($expect_sql, 0, "_mk_select_joined_sql(): param.gt",
    "test_person",{
        "_order" => [ "first_name.gt", "age.gt", "birth_dt.gt", ],
        "first_name.gt" => "stephen",
        "age.gt" => "37",
        "birth_dt.gt" => "1962-01-01",
    },["first_name"]);

$expect_sql = <<EOF;
select
   t1.first_name cn1
from
   test_person t1
where t1.first_name <= 'stephen'
  and t1.age <= 37
  and t1.birth_dt <= '1962-01-01'
EOF
&test_get_rows($expect_sql, 0, "_mk_select_joined_sql(): param.le",
    "test_person",{
        "_order" => [ "first_name.le", "age.le", "birth_dt.le", ],
        "first_name.le" => "stephen",
        "age.le" => "37",
        "birth_dt.le" => "1962-01-01",
    },["first_name"]);

$expect_sql = <<EOF;
select
   t1.first_name cn1
from
   test_person t1
where t1.first_name < 'stephen'
  and t1.age < 37
  and t1.birth_dt < '1962-01-01'
EOF
&test_get_rows($expect_sql, 0, "_mk_select_joined_sql(): param.lt",
    "test_person",{
        "_order" => [ "first_name.lt", "age.lt", "birth_dt.lt", ],
        "first_name.lt" => "stephen",
        "age.lt" => "37",
        "birth_dt.lt" => "1962-01-01",
    },["first_name"]);

$expect_sql = <<EOF;
select
   t1.first_name cn1
from
   test_person t1
where t1.first_name like '%s%'
  and t1.age like '%3%'
  and t1.birth_dt like '%1962%'
EOF
&test_get_rows($expect_sql, 0, "_mk_select_joined_sql(): param.contains",
    "test_person",{
        "_order" => [ "first_name.contains", "age.contains", "birth_dt.contains", ],
        "first_name.contains" => "s",
        "age.contains" => "3",
        "birth_dt.contains" => "1962",
    },["first_name"]);

$expect_sql = <<EOF;
select
   t1.first_name cn1
from
   test_person t1
where t1.first_name like '%s%'
  and t1.age like '%3'
  and t1.birth_dt like '1962%'
EOF
&test_get_rows($expect_sql, 0, "_mk_select_joined_sql(): param.matches",
    "test_person",{
        "_order" => [ "first_name.matches", "age.matches", "birth_dt.matches", ],
        "first_name.matches" => "*s*",
        "age.matches" => "*3",
        "birth_dt.matches" => "1962*",
    },["first_name"]);

$expect_sql = <<EOF;
select
   t1.first_name cn1,
   t1.last_name cn2,
   t1.age cn13
from
   test_person t1
where t1.age >= 37
limit 1
EOF
&test_get_rows($expect_sql,0,"_mk_select_joined_sql(): cols, endrow", "test_person",{"age.ge" => 37},["first_name","last_name","age"],{startrow => 1, endrow => 1});

$expect_sql = <<EOF;
select
   t1.first_name cn1,
   t1.last_name cn2,
   t1.city cn4,
   t1.state cn5,
   t1.age cn13
from
   test_person t1
order by
   cn2 asc,
   cn4,
   t1.address,
   t1.gender desc,
   cn1
EOF
&test_get_rows($expect_sql, 0, "_mk_select_joined_sql(): ordercols, directions",
    "test_person",{},["first_name","last_name","city","state","age"],
    {ordercols=>["last_name","city","address","gender","first_name"],
     directions=>{last_name=>"ASC",city=>"",address=>undef,gender=>"Desc"}});

$expect_sql = <<EOF;
select
   t1.first_name,
   t1.last_name,
   t1.city,
   t1.state,
   t1.age
from test_person
where age in (14,15,16,17,18)
EOF
&test_get_rows($expect_sql, 0, "_mk_select_joined_sql(): verbatim (boo. hiss. evil.)",
    "test_person",
    {"age.verbatim" => "age in (14,15,16,17,18)"},
    ["first_name","last_name","city","state","age"]);
$sql = $rep->_mk_select_sql("test_person",
                            {"age.verbatim" => "age in (14,15,16,17,18)"},
                            ["first_name","last_name","city","state","age"]);
is($sql, $expect_sql, "_mk_select_sql(): verbatim (boo. hiss. evil.)");
&check_select($sql,0);

exit 0;

