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
    debug_sql => $App::options{debug_sql},
    trace => $App::options{trace},
);

# my $options= $context->{options};
# print "OPTIONS: {", join("|", %$options), "}\n";

my $db = $context->repository();

my $t_dir = "t";
$t_dir = "." if (! -d $t_dir);

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
    is($db->insert_rows("test_person", ["person_id","age","first_name","gender","state"],
        [[1,39,"stephen",  "M","GA"],
         [2,37,"susan",    "F","GA"]]),2,
        "insert rows (2 rows, primary key included)");
    is($db->get("test_person",1,"first_name"), "stephen", "1st row got in [stephen]");
    is($db->get("test_person",2,"first_name"), "susan",   "2nd row got in [susan]");

    is($db->import_rows("test_person", ["age","first_name","gender","state"],
        "$t_dir/files/DBI-import.01.dat", {field_sep => "|", import_method => "insert"}),
        120,
        "import from file [files/DBI-import.01.dat]");
    is($db->get("test_person",3,"first_name"), "mike",    "3rd row got in [mike]");
    is($db->get("test_person",4,"first_name"), "mary",    "4th row got in [mary]");
    is($db->get("test_person",5,"first_name"), "maxwell", "5th row got in [maxwell]");
    is($db->get("test_person",6,"first_name"), "myrtle",  "6th row got in [myrtle]");
}
__END__

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
}

exit 0;

