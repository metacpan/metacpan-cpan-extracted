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
            alias => "tp",
            primary_key => ["person_id"],
            column => {
              birth_dow => {
                dbexpr => "weekday(tp.birth_dt)",
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
$dbh->do("insert into test_person (person_id,age,first_name,gender,state) values (1,39,'stephen',  'M','GA')");
$dbh->do("insert into test_person (person_id,age,first_name,gender,state) values (2,37,'susan',    'F','GA')");
$dbh->do("insert into test_person (person_id,age,first_name,gender,state) values (3, 6,'maryalice','F','GA')");
$dbh->do("insert into test_person (person_id,age,first_name,gender,state) values (4, 3,'paul',     'M','GA')");
$dbh->do("insert into test_person (person_id,age,first_name,gender,state) values (5, 1,'christine','F','GA')");
$dbh->do("insert into test_person (person_id,age,first_name,gender,state) values (6,45,'tim',      'M','GA')");
$dbh->do("insert into test_person (person_id,age,first_name,gender,state) values (7,39,'keith',    'M','GA')");

my $columns = [ "person_id", "age", "first_name", "gender", "state", "birth_dt" ];

sub check_exec {
    my ($sql, $expected_rows) = @_;

    my ($nrows);
    eval {
        $nrows = $dbh->do($sql);
    };
    is($@,"","sql ok");

    if (defined $expected_rows) {
        is($nrows, $expected_rows, "num rows $expected_rows");
    }
}

my ($sql, $expect_sql, $rows, $nrows);

###############################################################################
# UPDATE
###############################################################################

my $rows1 = [
  [ 5, 1,'christine','F','GA'],
  [ 7,39,'keith',    'M','GA'],
  [ 3, 6,'maryalice','F','GA'],
  [ 4, 3,'paul',     'M','GA'],
  [ 1,39,'stephen',  'M','GA'],
  [ 2,37,'susan',    'F','GA'],
  [ 6,45,'tim',      'M','GA'],
];

# delete age 6
my $rows2 = [
  [ 5, 1,'christine','F','GA'],
  [ 7,39,'keith',    'M','GA'],
  [ 4, 3,'paul',     'M','GA'],
  [ 1,39,'stephen',  'M','GA'],
  [ 2,37,'susan',    'F','GA'],
  [ 6,45,'tim',      'M','GA'],
];

# delete age >= 39, gender in ('M','F'), person_id > 5
my $rows3 = [
  [ 5, 1,'christine','F','GA'],
  [ 4, 3,'paul',     'M','GA'],
  [ 1,39,'stephen',  'M','GA'],
  [ 2,37,'susan',    'F','GA'],
];

# delete first_name matches 's*' and gender contains 'M'
my $rows4 = [
  [ 5, 1,'christine','F','GA'],
  [ 4, 3,'paul',     'M','GA'],
  [ 2,37,'susan',    'F','GA'],
];

$rows = $rep->get_rows("test_person", {},
    ["person_id","age","first_name","gender","state"],
    {ordercols=>["first_name"],});
is_deeply($rows,$rows1,"rows after deleting age 6");

$expect_sql = <<EOF;
delete from test_person
where age = 6
EOF
$sql = $rep->_mk_delete_sql("test_person",{age => 6});
is($sql, $expect_sql, "_mk_delete_sql(): 1 param");

$expect_sql = <<EOF;
delete from test_person
where age = 6
  and gender = 'F'
EOF
$sql = $rep->_mk_delete_sql("test_person",{_order => ["age","gender"], age => 6, gender => "F"});
is($sql, $expect_sql, "_mk_delete_sql(): 2 params");

&check_exec($sql,1);

$rows = $rep->get_rows("test_person", {},
    ["person_id","age","first_name","gender","state"],
    {ordercols=>["first_name"],});
is_deeply($rows,$rows2,"rows after deleting age 6");

$nrows = $rep->delete("test_person", {"age.ge" => 39, gender => "M,F", "person_id.gt" => 5});
is($nrows,2,"delete() 2 rows");

$rows = $rep->get_rows("test_person", {},
    ["person_id","age","first_name","gender","state"],
    {ordercols=>["first_name"],});
is_deeply($rows,$rows3,"rows after deleting 3 params");

$expect_sql = <<EOF;
delete from test_person
where first_name like 's%'
  and gender like '%M%'
EOF
$sql = $rep->_mk_delete_sql("test_person",
   {
      _order => ["first_name.matches","gender.contains"],
      "first_name.matches" => "s*",
      "gender.contains" => "M"
   }
);
is($sql, $expect_sql, "_mk_delete_sql(): matches/contains params");

&check_exec($sql,1);

$rows = $rep->get_rows("test_person", {},
    ["person_id","age","first_name","gender","state"],
    {ordercols=>["first_name"],});
is_deeply($rows,$rows4,"rows after deleting with matches/contains");

$expect_sql = <<EOF;
delete from test_person
where weekday(birth_dt) in (1,7)
EOF
$sql = $rep->_mk_delete_sql("test_person", { "birth_dow" => "1,7" });
is($sql, $expect_sql, "_mk_delete_sql(): dbexpr");

$expect_sql = <<EOF;
delete from test_person
where birth_dt >= '1960-01-01'
  and birth_dt <= '1965-12-31'
EOF
$sql = $rep->_mk_delete_sql("test_person",
   {
      _order => [ "begin_birth_dt", "end_birth_dt" ],
      "begin_birth_dt" => "1960-01-01",
      "end_birth_dt" => "1965-12-31",
   });
is($sql, $expect_sql, "_mk_delete_sql(): begin/end params (quoted)");

$expect_sql = <<EOF;
delete from test_person
where birth_dt >= '19600101'
  and birth_dt <= '19651231'
EOF
$sql = $rep->_mk_delete_sql("test_person",
   {
      _order => [ "begin_birth_dt", "end_birth_dt" ],
      "begin_birth_dt" => "19600101",
      "end_birth_dt" => "19651231",
   });
is($sql, $expect_sql, "_mk_delete_sql(): begin/end params (unquoted)");

exit 0;

