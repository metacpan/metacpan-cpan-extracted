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

use_ok("App");
use_ok("App::Repository");
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
                    },
                },
            },
        },
    },
);

my $db = $context->repository();

$App::trace = 0;
$App::trace = 0;

{
    #cheating... I know its a DBI, but I have to set up the test somehow
    my $dbh     = $db->{dbh};
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
    $db->_load_rep_metadata();
}

{
    ok($db->_insert_row("test_person", ["person_id","age","first_name","gender","state"],
        [1,39,"stephen",  "M","GA"]),
        "insert row (primary key included)");
    ok($db->_insert_row("test_person", ["age","first_name","gender","state"],
        [37,"susan",    "F","GA"]),
        "insert row (primary key excluded, auto_increment)");
    ok($db->_insert_row("test_person", ["person_id","age","first_name","gender","state"],
        [undef, 6,"maryalice","F","GA"]),
        "insert row (primary key included, null)");
    ok($db->_insert_row("test_person", ["person_id","age","first_name","gender","state"],
        [0, 3,"paul",     "M","GA"]),
        "insert row (primary key included, 0)");
    ok($db->_insert_row("test_person", ["person_id","age","first_name","gender","state"],
        [5, 1,"christine","F","GA"]),
        "insert again");
    ok($db->_insert_row("test_person", ["person_id","age","first_name","gender","state"],
        [6,45,"tim",      "M","GA"]),
        "insert again");
    ok($db->_insert_row("test_person", ["person_id","age","first_name","gender","state"],
        [7,39,"keith",    "M","GA"]),
        "insert again");
    ok($db->insert("test_person", {
            person_id => 8,
            age => 35,
            first_name => "alex",
            gender => "M",
            state => "GA",
        }),
        "insert hash");
    eval {
        $db->insert_row("test_person", {
            person_id => 8,
            age => 35,
            first_name => "alex",
            gender => "M",
            state => "GA",
        });
    };
    ok($@, "insert dup hash fails");
    ok($db->insert("test_person", undef, {
            person_id => 9,
            age => 35,
            first_name => "alex",
            gender => "M",
            state => "GA",
        }),
        "insert hash in 2nd pos");
    ok($db->insert("test_person", ["age","first_name","gender","state"], {
            person_id => 9,
            age => 35,
            first_name => "alex",
            gender => "M",
            state => "GA",
        }),
        "insert hash in 2nd pos w/ col spec");
    eval {
        $db->insert_row("test_person", undef, {
            person_id => 9,
            age => 35,
            first_name => "alex",
            gender => "M",
            state => "GA",
        });
    };
    ok($@, "insert dup hash in 2nd pos fails");

    ok($db->insert("test_person", undef, {
            person_id => 11,
            age => 999,
            first_name => '%@$\\\'',
            gender => "M",
            state => "GA",
        }),
        "insert \\ and ' and \\' seems to work");
    is($db->get("test_person",11,"first_name"),'%@$\\\'', "yep. first_name worked.");

    my $new_hashes =
       [{ age=>39, first_name=>"stephen", gender=>"M", state=>"GA", foo=>"bar"},
        { age=>37, first_name=>"susan", gender=>"F", state=>"GA", foo=>"bar"},
        { age=>6, first_name=>"maryalice", gender=>"F", state=>"GA", foo=>"bar"},
        { age=>3, first_name=>"paul", gender=>"M", state=>"GA", foo=>"bar"},
        { age=>1, first_name=>"christine", gender=>"F", state=>"GA", foo=>"bar"},
        { age=>45, first_name=>"tim", gender=>"M", state=>"GA", foo=>"bar"},
        { age=>39, first_name=>"keith", gender=>"M", state=>"GA", foo=>"bar"},];

    my $new_rows =
       [[39,"stephen",  "M","GA"],
        [37,"susan",    "F","GA"],
        [6,"maryalice", "F","GA"],
        [3,"paul",      "M","GA"],
        [1,"christine", "F","GA"],
        [45,"tim",      "M","GA"],
        [39,"keith",    "M","GA"],];

    my $dup_rows =
       [[1, 39,"stephen",  "M","GA"],
        [2, 37,"susan",    "F","GA"],
        [3, 6,"maryalice", "F","GA"],
        [4, 3,"paul",      "M","GA"],
        [5, 1,"christine", "F","GA"],
        [6, 45,"tim",      "M","GA"],
        [7, 39,"keith",    "M","GA"],];

    my ($expect_sql, $sql);
$expect_sql = <<EOF;
insert into test_person
  (age, first_name, gender, state)
values
  (39, 'stephen', 'M', 'GA'),
  (37, 'susan', 'F', 'GA'),
  (6, 'maryalice', 'F', 'GA'),
  (3, 'paul', 'M', 'GA'),
  (1, 'christine', 'F', 'GA'),
  (45, 'tim', 'M', 'GA'),
  (39, 'keith', 'M', 'GA')
EOF
$sql = $db->_mk_insert_rows_sql("test_person", ["age","first_name","gender","state"], $new_rows);
is($sql, $expect_sql, "_mk_insert_rows_sql(): 7 rows, bulk insert");
$sql = $db->_mk_insert_rows_sql("test_person", ["age","first_name","gender","state"], $new_hashes);
is($sql, $expect_sql, "_mk_insert_rows_sql(): 7 rows, bulk insert (from hashes)");

$expect_sql = <<EOF;
replace into test_person
  (age, first_name, gender, state)
values
  (39, 'stephen', 'M', 'GA'),
  (37, 'susan', 'F', 'GA'),
  (6, 'maryalice', 'F', 'GA'),
  (3, 'paul', 'M', 'GA'),
  (1, 'christine', 'F', 'GA'),
  (45, 'tim', 'M', 'GA'),
  (39, 'keith', 'M', 'GA')
EOF
$sql = $db->_mk_insert_rows_sql("test_person", ["age","first_name","gender","state"], $new_rows, { replace => 1 });
is($sql, $expect_sql, "_mk_insert_rows_sql(): 7 rows, bulk replace");

$expect_sql = <<EOF;
insert into test_person
  (person_id, age, first_name, gender, state)
values
  (1, 39, 'stephen', 'M', 'GA'),
  (2, 37, 'susan', 'F', 'GA'),
  (3, 6, 'maryalice', 'F', 'GA'),
  (4, 3, 'paul', 'M', 'GA'),
  (5, 1, 'christine', 'F', 'GA'),
  (6, 45, 'tim', 'M', 'GA'),
  (7, 39, 'keith', 'M', 'GA')
on duplicate key update
   person_id = values(person_id),
   age = values(age),
   first_name = values(first_name),
   gender = values(gender),
   state = values(state)
EOF
$sql = $db->_mk_insert_rows_sql("test_person", ["person_id", "age","first_name","gender","state"], $dup_rows, { update => 1 });
is($sql, $expect_sql, "_mk_insert_rows_sql(): 7 rows, bulk insert/update");

#######################################
my ($nrows);
$nrows = $db->insert_rows("test_person", ["age","first_name","gender","state"], $new_rows);
is($nrows, 7, "insert_rows(): 7 rows, bulk insert");
$nrows = $db->insert_rows("test_person", ["person_id","age","first_name","gender","state"], $dup_rows, { replace => 1 });
is($nrows, 7, "insert_rows(): 7 rows, bulk replace");
$nrows = $db->insert_rows("test_person", ["person_id", "age","first_name","gender","state"], $dup_rows, { update => 1 });
is($nrows, 7, "insert_rows(): 7 rows, bulk insert/update");
$nrows = $db->insert_rows("test_person", ["person_id","age","first_name","gender","state"], $dup_rows, { replace => 1, maxrows => 4 });
is($nrows, 7, "insert_rows(): 7 rows, bulk replace (4 at a time)");
$nrows = $db->insert_rows("test_person", ["person_id", "age","first_name","gender","state"], $dup_rows, { update => 1, maxrows => 4 });
is($nrows, 7, "insert_rows(): 7 rows, bulk insert/update (4 at a time)");

}

exit 0;

