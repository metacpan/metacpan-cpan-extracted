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
        SessionObject => {
            adults => {
                class => "App::SessionObject::RepositoryObjectSet",
                #repository => "default",
                table => "test_person",
                #params => {
                #    "age.ge" => 18,
                #},
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
    my $objset = $context->session_object("adults");
    ok(1, "looks good");
    my ($objects, $index);
    #eval {
    #    $objects = $objset->get_objects();
    #};
    #ok($@ =~ /table not defined/, "table not defined");
    #$objset->set_table("test_person");
    $objects = $objset->get_objects();
    ok($#$objects == 6, "got all 7 objects");
    $objset->set_params({ "age.ge" => 18 });
    $objects = $objset->get_objects();
    ok($#$objects == 3, "got 4 objects");
    $objset->set_params({});
    $objects = $objset->get_objects("F",["gender"]);
    ok($#$objects == 2, "got 3 female objects");
    $objects = $objset->get_objects("M","gender");
    ok($#$objects == 3, "got 4 male objects");
    $index = $objset->get_index("gender");
    ok(ref($index) eq "HASH", "got a hashref for an index");
    ok(defined $index->{M}, "M part of index found");
    ok(defined $index->{F}, "F part of index found");
    ok(ref($index->{M}) eq "ARRAY", "M part of index ARRAY ref");
    ok(ref($index->{F}) eq "ARRAY", "F part of index ARRAY ref");
    my $values = $objset->get_column_values("gender");
    is_deeply($values, ["M","F"], "gender values");
    $index = $objset->get_unique_index("ak1", ["first_name"]);
    is($index->{stephen}{age}, 39, "get_unique_index worked on stephen");
    $objset->set_params({ "age.ge" => 1 });
    $objset->update_params({ "age.ge" => 18, first_name => "stephen"});
    $objects = $objset->get_objects();
    ok($#$objects == 3, "got 4 objects");
    $objset->get_unique_index(["first_name"]);
    my $object = $objset->get_object("stephen","first_name");
    ok($object->{age} == 39, "got stephen object (age 39)");

    # max_age
    $rep->set("test_person",1,"age",40);
    $objects = $objset->get_objects();   # NOTE: objects are cached. we miss the update.
    is($objects->[0]{age}, 39, "max_age: no refresh without max_age");
    $objects = $objset->get_objects({max_age => 100});  # NOTE: objects are cached. we miss the update.
    is($objects->[0]{age}, 39, "max_age: no refresh with big max_age");
    $objects = $objset->get_objects({max_age => 0});  # NOTE: we get the update.
    is($objects->[0]{age}, 40, "max_age: refresh with small max_age");
    $rep->set("test_person",1,"age",41);
    $objset->{max_age} = 0;
    $objects = $objset->get_objects({max_age => 100});  # NOTE: objects are cached. we miss the update.
    is($objects->[0]{age}, 40, "max_age: no refresh by overriding small max_age on objset with large max_age");
    $objects = $objset->get_objects();                # NOTE: we get the update.
    is($objects->[0]{age}, 41, "max_age: refresh with max_age on objset");

    $rep->_disconnect();
    my $hashes = [
        { person_id => 1, age => 39, name => "stephen",   gender => "M", state => "GA", num_kids => 3, },
        { person_id => 2, age => 37, name => "susan",     gender => "F", state => "GA", num_kids => 3, },
        { person_id => 3, age =>  6, name => "maryalice", gender => "F", state => "GA", num_kids => 0, },
        { person_id => 4, age =>  3, name => "paul",      gender => "M", state => "GA", num_kids => 0, },
        { person_id => 5, age =>  1, name => "christine", gender => "F", state => "GA", num_kids => undef, },
        { person_id => 6, age => 45, name => "tim",       gender => "M", state => "GA", num_kids => 2, },
        { person_id => 7, age => 39, name => "keith",     gender => "M", state => "GA", num_kids => 4, },
    ];
    my $new_object_set  = $rep->create_temporary_object_set("test_person", {fee => 1, fie => 2, foe => "fum"}, undef, $hashes);
    my $new_object_set2 = $rep->create_temporary_object_set("test_person", {fee => 1, fie => 2, foe => "fum"}, undef, $hashes);
    is(ref($new_object_set), "App::SessionObject::RepositoryObjectSet", "Correct class (RepositoryObjectSet)");
    ok($new_object_set->{temporary}, "new_object_set (temporary) has {temporary} attribute set");

    #$App::trace = 1;

    $new_object_set->{foo} = "bar";
    ok(! defined $new_object_set2->{foo}, "new_object_set()s (temporary) don't share storage");
    my $hashes2 = $new_object_set->get_objects();
    is($hashes2, $hashes, "Got same exact reference to set of objects");
    is($#$hashes2, $#$hashes, "Got same exact number of objects");
    is($rep, $new_object_set->get_repository(), "Got same exact reference to a repository");
    is("test_person", $new_object_set->get_table(), "Got same exact table");
    my $columns = $new_object_set->get_columns();
    is($#$columns, 5, "Got 6 columns");
    is($columns->[0], "age", "Got 1st column as age");

    $index = $new_object_set->get_index(["gender"]);
    my $females = $index->{F};
    is($#$females, 2, "Got 3 females");
    is($females->[0]{name}, "susan", "Got susan as 1st female");

    $index = $new_object_set->get_index(["state"]);
    my $georgians = $index->{GA};
    is($#$georgians, 6, "Got 7 georgians");
    is($georgians->[3]{name}, "paul", "Got paul as 4th georgian");

    $index = $new_object_set->get_index(["gender","age"]);
    my $m39s = $index->{"M,39"};
    is($#$m39s, 1, "Got 2 m39s");
    is($m39s->[1]{name}, "keith", "Got keith as 2nd m39");
    
    $index = $new_object_set->get_unique_index(["gender","age"]);
    my $m39 = $index->{"M,39"};
    ok($m39, "Got an m39");
    is($m39->{name}, "keith", "Got keith as the last (assumed unique) m39");
    
    my $summaries = $new_object_set->get_summary([]);
    is(ref($summaries), "HASH", "Got summary hash");
    is($summaries->{""}{num_kids}, 12, "Got 12 total kids");
    
    my $ext_summary = $new_object_set->get_ext_summary([]);
    is(ref($ext_summary), "HASH", "Got summary hash");
    is($ext_summary->{""}{num_kids}{sum},      12, "Got sum 12 kids");
    is($ext_summary->{""}{num_kids}{average},  2, "Got average 2 kids");
    is($ext_summary->{""}{num_kids}{count},    6, "Got count 6 kids");
    is(ref($ext_summary->{""}{num_kids}{distinct}), "HASH", "Got distinct hashref");
    my $distinct_values = [ keys %{$ext_summary->{""}{num_kids}{distinct}} ];
    is($#$distinct_values, 3, "Got distinct 4 kids");
    is($ext_summary->{""}{num_kids}{min},      0, "Got min 2 kids");
    is($ext_summary->{""}{num_kids}{max},      4, "Got max 2 kids");
    is($ext_summary->{""}{num_kids}{sum_sq},   38, "Got sum_sq 2 kids");
    is($ext_summary->{""}{num_kids}{median},   2.5, "Got median 2 kids");
    ok($ext_summary->{""}{num_kids}{stddev} >= 1.6733200 && $ext_summary->{""}{num_kids}{stddev} <= 1.6733201, "Got stddev 1.673320 kids");
    is($ext_summary->{""}{num_kids}{mode},     2, "Got mode 2 kids");

    my $column_values = $new_object_set->get_column_values("gender");
    is($#$column_values, 1, "Got 2 column_values for gender");
    is($column_values->[0], "M", "Got M as first gender value");
    is($column_values->[1], "F", "Got F as second gender value");

    $object = $new_object_set->get_object(1, ["person_id"]);
    is($object->{name}, "stephen", "Got stephen as person_id 1");
    $object = $new_object_set->get_object("39,keith", ["age","name"]);
    is($object->{name}, "keith", "Got keith as person_id named keith age 39");

    $females = $new_object_set->get_objects("F",["gender"]);
    is($#$females, 2, "Got 3 females (without explicit use of an index)");
    is($females->[0]{name}, "susan", "Got susan as 1st female (without explicit use of an index)");

    ok(! defined $rep->{dbh}, "Never reconnected to the database");
}

{
    $rep->_connect();
    my $dbh = $rep->{dbh};
    $dbh->do("drop table test_person");
}

exit 0; 
