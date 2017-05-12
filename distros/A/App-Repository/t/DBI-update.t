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

my ($sql, $expect_sql);

###############################################################################
# UPDATE
###############################################################################
$expect_sql = <<EOF;
update test_person set
   age = 6
EOF
#$sql = $rep->_mk_update_sql("test_person",{},"age",6);
#is($sql, $expect_sql, "_mk_update_sql(): 1 col, no params");
#&check_exec($sql,7);

$sql = $rep->_mk_update_sql("test_person",undef,["age"],[6]);
is($sql, $expect_sql, "_mk_update_sql(): 1 col, undef params");
&check_exec($sql,7);

$sql = $rep->_mk_update_sql("test_person",{},["age"],[6]);
is($sql, $expect_sql, "_mk_update_sql(): 1 col, no params");
&check_exec($sql,7);

$expect_sql = <<EOF;
update test_person set
   age = 6,
   state = 'GA'
where person_id = 4
EOF
$sql = $rep->_mk_update_sql("test_person",4,["age","state"],[6,"GA"]);
is($sql, $expect_sql, "_mk_update_sql(): 2 cols, by key");
&check_exec($sql,1);

$expect_sql = <<EOF;
update test_person set
   age = 6,
   state = 'GA'
where person_id = 4
EOF
$sql = $rep->_mk_update_sql("test_person",4,["age","state"],{age => 6, state => "GA"});
is($sql, $expect_sql, "_mk_update_sql(): 2 cols, by key, row is a hashref");
&check_exec($sql,1);

$expect_sql = <<'EOF';
update test_person set
   first_name = '%@$\\\''
where person_id = 4
EOF
$sql = $rep->_mk_update_sql("test_person",4,["first_name"],['%@$\\\'']);
is($sql, $expect_sql, "_mk_update_sql(): proper quoting for \\'");
&check_exec($sql,1);

# This doesn't work yet
#$expect_sql = <<EOF;
#update test_person set
#   age = 6
#where person_id = 4
#EOF
#$sql = $rep->_mk_update_sql("test_person",4,{age => 6});
#is($sql, $expect_sql, "_mk_update_sql(): 1 col, by key, cols/row is single hashref");
#&check_exec($sql,1);

exit 0;

