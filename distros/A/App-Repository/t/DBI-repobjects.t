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
use App::RepositoryObject;

package App::RepositoryObject::Man;
@ISA = ("App::RepositoryObject");
$VERSION = 0.01;

package App::RepositoryObject::Woman;
@ISA = ("App::RepositoryObject");
$VERSION = 0.01;

package main;

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
                        class => [
                            [ "gender", "F", "App::RepositoryObject::Woman" ],
                            # [ undef,  undef, "App::RepositoryObject::Man" ],  # otherwise Man
                        ],
                        primary_key => ["person_id"],
                    },
                },
            },
        },
    },
);

my $rep = $context->repository();

{
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
}

###########################################################################
# DATA ACCESS TESTS
###########################################################################
my ($person_id, $first_name, $last_name, $address, $city, $state, $zip, $country);
my ($home_phone, $work_phone, $email_address, $gender, $birth_dt, $age);

my $columns = [ "person_id", "age", "first_name", "gender", "state" ];
my $rows = [
    [ 1, 39, "stephen",   "M", "GA", ],
    [ 2, 37, "susan",     "F", "GA", ],
    [ 3,  6, "maryalice", "F", "GA", ],
    [ 4,  3, "paul",      "M", "GA", ],
    [ 5,  1, "christine", "F", "GA", ],
    [ 6, 45, "tim",       "M", "GA", ],
    [ 7, 39, "keith",     "M", "GA", ],
];

my ($row, $nrows);

#####################################################################
#  $value  = $rep->get ($table, $key,     $col,   \%options);
#  $rep->set($table, $key,     $col,   $value,    \%options);
#####################################################################
{
    my $obj = $rep->get_object("test_person", 1);
    isa_ok($obj, "App::RepositoryObject", "stephen");
    $first_name = $obj->get("first_name");
    is($first_name, "stephen", "get() first_name [$first_name]");
    is($obj->set("first_name", "steve"),1,"set() first name [steve]");
}
{
    my $obj = $rep->get_object("test_person", 1);
    $first_name = $obj->get("first_name");
    is($first_name, "steve", "get() modified first_name [$first_name]");
    $age = $obj->get("age");
    is($age, 39, "get() age");
}
{
    my $obj = $rep->get_object("test_person", 1, []);
    $first_name = $obj->get("first_name");
    is($first_name, "steve", "get() modified first_name [$first_name] from uninit object");
    $age = $obj->get("age");
    is($age, 39, "get() age from uninit object");
}

{
    my $obj = $rep->get_object("test_person", 2, []);
    isa_ok($obj, "App::RepositoryObject", "susan");
    ok($obj->set(["first_name","age"], ["sue",38]), "set() 2 values");
    ($first_name, $age) = $obj->get(["first_name","age"]);
    is($first_name, "sue", "get() 2 values (checking 1 of 2)");
    is($age, 38, "get() 2 values (checking 2 of 2)");
}

{
    my $obj = $rep->get_object("test_person", 2);
    isa_ok($obj, "App::RepositoryObject::Woman", "susan");
}

{
    my $objs = $rep->get_objects("test_person", {}, undef, {order_by => "person_id"});
    is($objs->[0]{_key}, 1, "get_objects() automatically set the _key");
    isa_ok($objs->[0], "App::RepositoryObject", "by get_objects(), stephen");
    isa_ok($objs->[1], "App::RepositoryObject::Woman", "by get_objects(), susan");
}

{
    my $obj = $rep->get_object("test_person", {}, undef, {order_by => "person_id"});
    is($obj->{_key}, 1, "get_object() automatically set the _key");
}

{
    ok($rep->set_row("test_person", {first_name=>'paul'}, ["age", "state"], [5, "CA"]),"set_row() 2 values w/ %crit");
    my $obj = $rep->get_object("test_person", {first_name=>'paul'}, ["age", "state","person_id"]);
    is($obj->{age},         5, "get_object() 3 values w/ %crit (checking 1 of 3)");
    is($obj->{state},    "CA", "get_object() 3 values w/ %crit (checking 2 of 3)");
    is($obj->{person_id},   4, "get_object() 3 values w/ %crit (checking 3 of 3)");
}

{
    my $obj = $rep->get_object("test_person", 1);
    is($obj->{_key}, 1, "get_object() by key");
    my $retval = $obj->delete();
    ok($retval, "delete() seems to have worked");
    my $obj2 = $rep->get_object("test_person", 1);
    ok(! defined $obj2, "delete() yep, it's really gone");
    $obj2 = $rep->new_object("test_person", $obj);
    is($obj2->{first_name},$obj->{first_name}, "new.first_name seems ok");
    is($obj2->{age},$obj->{age}, "new.age seems ok");
    is($obj2->{_key},$obj->{_key}, "new._key seems ok");
    my $obj3 = $rep->get_object("test_person", 1);
    ok(defined $obj2, "new() it's back");
    is($obj3->{first_name},$obj->{first_name}, "new.first_name seems ok");
    is($obj3->{age},$obj->{age}, "new.age seems ok");
    is($obj3->{_key},$obj->{_key}, "new._key seems ok");
    my $obj4 = $rep->new_object("test_person",{first_name => "christine", gender => "F"});
    is($obj4->{first_name},"christine", "new.first_name (2) seems ok");
    is($obj4->{_key},8, "new._key is ok");
    is($obj4->{person_id},8, "new.person_id is ok");
    isa_ok($obj4, "App::RepositoryObject::Woman", "by new_object(), christine");
}

{
    my $dbh = $rep->{dbh};
    $dbh->do("drop table test_person");
}

exit 0;

