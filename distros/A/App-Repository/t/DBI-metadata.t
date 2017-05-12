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
                    test_person2 => {
                        primary_key => "last_name,first_name",
                    },
                    test_person3 => {
                        primary_key => [ "person_id" ],
                    },
                    test_person4 => {
                        primary_key => "person_id",
                    },
                },
            },
        },
    },
);

my $db = $context->repository();

{
    #cheating... I know its a DBI, but I have to set up the test somehow
    my $dbh     = $db->{dbh};
    eval { $dbh->do("drop table if exists app_cache"); };
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
    chess_rating       float        null,
    modify_dttm        datetime     null,
    index person_ie1 (last_name, first_name)
)
EOF
    my $success = $dbh->do($ddl);
    #print "create table = [$success]\n";
}

###########################################################################
# METADATA TESTS
###########################################################################
my $table_names = $db->get_table_names();
print "tables=[@$table_names]\n";
my %tables = ( map { $_ => 1 } @$table_names );
ok(defined $tables{test_person}, "get_table_names()");
$db->_load_rep_metadata();
$db->_load_table_metadata("test_person");
$db->_load_table_metadata("test_person2");
$db->_load_table_metadata("test_person3");
$db->_load_table_metadata("test_person4");
is_deeply($db->{table}{test_person}{primary_key}, ["person_id"], "primary_key set from db");
is_deeply($db->{table}{test_person2}{primary_key}, ["last_name", "first_name"], "primary_key set from config (comma-sep)");
is_deeply($db->{table}{test_person3}{primary_key}, ["person_id"], "primary_key set from config (scalar)");
is_deeply($db->{table}{test_person4}{primary_key}, ["person_id"], "primary_key set from config (scalar)");

my $tabledef = $db->get_table_def("test_person");
is($tabledef->{column}{person_id}{type},    "integer",  "person_id type is integer");
is($tabledef->{column}{first_name}{type},   "string",   "first_name type is integer");
is($tabledef->{column}{country}{type},      "string",   "country type is integer");
is($tabledef->{column}{gender}{type},       "string",   "gender type is integer");
is($tabledef->{column}{birth_dt}{type},     "date",     "birth_dt type is integer");
is($tabledef->{column}{age}{type},          "integer",  "age type is integer");
is($tabledef->{column}{chess_rating}{type}, "float",    "chess_rating type is integer");
is($tabledef->{column}{modify_dttm}{type},  "datetime", "modify_dttm type is integer");

is($tabledef->{column}{person_id}{quoted},    0, "person_id quoted is 0");
is($tabledef->{column}{first_name}{quoted},   1, "first_name quoted is 1");
is($tabledef->{column}{country}{quoted},      1, "country quoted is 1");
is($tabledef->{column}{gender}{quoted},       1, "gender quoted is 1");
is($tabledef->{column}{birth_dt}{quoted},     1, "birth_dt quoted is 1");
is($tabledef->{column}{age}{quoted},          0, "age quoted is 0");
is($tabledef->{column}{chess_rating}{quoted}, 0, "chess_rating quoted is 0");
is($tabledef->{column}{modify_dttm}{quoted},  1, "modify_dttm quoted is 1");

#{
#    eval { $db->{dbh}->do("drop table test_person"); };
#}

exit 0;

