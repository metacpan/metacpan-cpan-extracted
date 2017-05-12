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
                            years_older => {
                                dbexpr => "age-{base_age:0}",
                            },
                        },
                    },
                },
            },
        },
    },
    debug_sql => $App::options{debug_sql},
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
    $dbh->do("insert into test_person (person_id,age,first_name,gender,state) values (6,45,'tim',      'M','FL')");
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
    [ 6, 45, "tim",       "M", "FL", ],
    [ 7, 39, "keith",     "M", "GA", ],
];

my ($row, $nrows);

#####################################################################
#  $value  = $rep->get ($table, $key,     $col,   \%options);
#  $rep->set($table, $key,     $col,   $value,    \%options);
#####################################################################
$first_name = $rep->get("test_person", 1, "first_name");
is($first_name, "stephen", "get() first_name [$first_name]");
is($rep->set("test_person", 1, "first_name", "steve"),1,"set() first name [steve]");
$first_name = $rep->get("test_person", 1, "first_name");
is($first_name, "steve", "get() modified first_name [$first_name]");
$age = $rep->get("test_person", 1, "age");
is($age, 39, "get() age");

ok($rep->set("test_person", 2, ["first_name","age"], ["sue",38]), "set() 2 values");
($first_name, $age) = $rep->get("test_person", 2, ["first_name","age"]);
is($first_name, "sue", "get() 2 values (checking 1 of 2)");
is($age, 38, "get() 2 values (checking 2 of 2)");

ok($rep->set_row("test_person", 3, ["age", "state"], [7, "CA"]),"set_row() 2 values");
$row = $rep->get_row("test_person", 4, ["age", "gender"]);
($age, $gender) = @$row;
is($age, 3, "get_row() 2 values (checking 1 of 2)");
is($gender, "M", "get_row() 2 values (checking 2 of 2)");

ok($rep->set_row("test_person", {first_name=>'paul'}, ["age", "state"], [5, "CA"]),"set_row() 2 values w/ %crit");
$row = $rep->get_row("test_person", {first_name=>'paul'}, ["age", "state","person_id"]);
($age, $state, $person_id) = @$row;
is($age,         5, "get_row() 3 values w/ %crit (checking 1 of 3)");
is($state,    "CA", "get_row() 3 values w/ %crit (checking 2 of 3)");
is($person_id,   4, "get_row() 3 values w/ %crit (checking 3 of 3)");

ok($rep->set_row("test_person", {first_name=>'paul'}, ["age", "state"], {age=>6, state=>"GA", person_id=>99}),
   "set_row() 2 values w/ %crit and values in hash");
$row = $rep->get_row("test_person", {first_name=>'paul'}, ["age", "state","person_id"]);
($age, $state, $person_id) = @$row;
is($age,         6, "get_row() 3 values w/ %crit (checking 1 of 3)");
is($state,    "GA", "get_row() 3 values w/ %crit (checking 2 of 3)");
is($person_id,   4, "get_row() 3 values w/ %crit (checking 3 of 3)");

my ($hashes, $hash);
ok($rep->set("test_person", 1, {person_id => 1, age => 41}), "set(table,\$key,\%hash)");
$hash = $rep->get_hash("test_person", 1);
is($hash->{person_id},  1,         "get_hash(1) person_id");
is($hash->{age},        41,        "get_hash(1) age");
is($hash->{first_name}, "steve",   "get_hash(1) first_name");
is($hash->{gender},     "M",       "get_hash(1) gender");
is($hash->{state},      "GA",      "get_hash(1) state");

ok($rep->set("test_person", {first_name => "steve"}, {person_id => 1, age => 41}), "set(table,\$params,\%hash)");
ok($rep->set("test_person", {person_id => 8, age => 37, first_name => "nick", gender => "M", state => undef},
    undef, undef, {create=>1}),
    "set(table,\$params,\%hash) : insert");
is($rep->set("test_person", {gender => "F", age => 41}), 0,
    "set(table,\$params,\%hash) : fails if key not supplied");
$hashes = $rep->get_hashes("test_person");
is($#$hashes, 7, "get_hashes(test_person) returned 8 rows");
$hashes = $rep->get_hashes("test_person",{},undef,{order_by=>["person_id"]});
is($#$hashes, 7, "get_hashes(test_person,{},undef,{order_by}) returned 8 rows");
#foreach $hash (@$hashes) {
#    print "HASH: {", join("|", %$hash), "}\n";
#}
$hash = $hashes->[0];
is($hash->{person_id},  1,         "get_hashes()->[0] person_id");
is($hash->{age},        41,        "get_hashes()->[0] age");
is($hash->{first_name}, "steve",   "get_hashes()->[0] first_name");
is($hash->{gender},     "M",       "get_hashes()->[0] gender");
is($hash->{state},      "GA",      "get_hashes()->[0] state");
$hash = $hashes->[$#$hashes];
is($hash->{person_id},  8,         "get_hashes()->[n] person_id");
is($hash->{age},        37,        "get_hashes()->[n] age");
is($hash->{first_name}, "nick",    "get_hashes()->[n] first_name");
is($hash->{gender},     "M",       "get_hashes()->[n] gender");
is($hash->{state},      undef,     "get_hashes()->[n] state");

eval {
    $nrows = $rep->set("test_person", undef, "gender", "M");
    print "updated $nrows rows. ?!? shouldn't ever get here!\n";
};
ok($@, "set() with undef params");

####################################################################
# Exercise the special implied where conditions
####################################################################
#my $rows2 = $rep->get_rows("test_person", {}, ["person_id","age","first_name","gender","state"]);
#foreach my $row (@$rows2) {
#    print "ROW: [", join("|", map { defined $_ ? $_ : "undef" } @$row), "]\n";
#}

$hashes = $rep->get_hashes("test_person", {first_name => "!steve,joe,nick"});
is($#$hashes+1, 6, "get_hashes(!steve,joe,nick)");
$hashes = $rep->get_hashes("test_person", {first_name => "steve,joe,nick"});
is($#$hashes+1, 2, "get_hashes(steve,joe,nick)");
$hashes = $rep->get_hashes("test_person", {first_name => "=steve,joe,nick"});
is($#$hashes+1, 2, "get_hashes(=steve,joe,nick)");
$hashes = $rep->get_hashes("test_person", {first_name => "==steve,joe,nick"});
is($#$hashes+1, 0, "get_hashes(==steve,joe,nick)");
$hashes = $rep->get_hashes("test_person", {state => "GA"});
is($#$hashes+1, 5, "get_hashes(GA)");
$hashes = $rep->get_hashes("test_person", {state => "GA,NULL"});
is($#$hashes+1, 6, "get_hashes(GA,NULL)");
$hashes = $rep->get_hashes("test_person", {state => "!GA,NULL"});
is($#$hashes+1, 2, "get_hashes(!GA,NULL)");
$hashes = $rep->get_hashes("test_person", {state => "GA,CA"});
is($#$hashes+1, 6, "get_hashes(GA,CA)");
$hashes = $rep->get_hashes("test_person", {state => "!GA,CA"});
is($#$hashes+1, 1, "get_hashes(!GA,CA)");
$hashes = $rep->get_hashes("test_person", {"state.not_in" => ["GA","CA"]});
is($#$hashes+1, 1, "get_hashes not_in [GA,CA]");
$hashes = $rep->get_hashes("test_person", {"state.not_in" => "GA,CA"});
is($#$hashes+1, 1, "get_hashes not_in (GA,CA)");
$hashes = $rep->get_hashes("test_person", {"state.in" => "!GA,CA"});
is($#$hashes+1, 1, "get_hashes in (!GA,CA)");
$hashes = $rep->get_hashes("test_person", {"state.eq" => "!GA,CA"});
is($#$hashes+1, 0, "get_hashes eq (!GA,CA)");
$hashes = $rep->get_hashes("test_person", {"state.contains" => "A"});
is($#$hashes+1, 6, "get_hashes contains (A)");
$hashes = $rep->get_hashes("test_person", {"state.not_contains" => "A"});
is($#$hashes+1, 1, "get_hashes not_contains (A)");

$hashes = $rep->get_hashes("test_person", {"state.matches" => "?A"});
is($#$hashes+1, 6, "get_hashes matches (?A)");
$hashes = $rep->get_hashes("test_person", {"state" => "?A"});
is($#$hashes+1, 6, "get_hashes (?A)");
$hashes = $rep->get_hashes("test_person", {"state.not_matches" => "?A"});
is($#$hashes+1, 1, "get_hashes not_matches (?A)");

#print $rep->{sql};

#####################################################################
# dbexpr with substitutions
#####################################################################
my ($years_older);
$years_older = $rep->get("test_person", {person_id => 1}, "years_older");
is($years_older, 41, "get() years_older [$years_older] base_age is undef");
$years_older = $rep->get("test_person", {person_id => 1, base_age => 20}, "years_older");
is($years_older, 21, "get() years_older [$years_older] base_age = 20");

exit(0);
#####################################################################
#  $rep->set_rows($table, undef,    \@cols, $rows, \%options);
#####################################################################
eval {
    $nrows = $rep->set_rows("test_person", undef, $columns, $rows);
};
is($nrows, 7, "set_rows() [test_person]");

#  $value  = $rep->get ($table, \%params, $col,   \%options);
#  @row    = $rep->get ($table, \%params, \@cols, \%options);

#  $rep->set($table, \%params, $col,   $value,    \%options);

#  @row    = $rep->get ($table, $key,     \@cols, \%options);
#  $row    = $rep->get_row ($table, $key,     \@cols, \%options);
#  $row    = $rep->get_row ($table, \%params, \@cols, \%options);

#  $rep->set_row($table, $key,     \@cols, $row, \%options);
#  $rep->set_row($table, \%params, \@cols, $row, \%options);
#  $rep->set_row($table, undef,    \@cols, $row, \%options);

#  $colvalues = $rep->get_col ($table, \%params, $col, \%options);

#  $rows = $rep->get_rows ($table, \%params, \@cols, \%options);
#  $rows = $rep->get_rows ($table, \%params, $col,   \%options);
#  $rows = $rep->get_rows ($table, \@keys,   \@cols, \%options);

#  $rep->set_rows($table, \%params, \@cols, $rows, \%options);
#  $rep->set_rows($table, \@keys,   \@cols, $rows, \%options);

#  $values = $rep->get_values ($table, $key,     \@cols, \%options);
#  $values = $rep->get_values ($table, \%params, \@cols, \%options);
#  $values = $rep->get_values ($table, $key,     undef,  \%options);
#  $values = $rep->get_values ($table, \%params, undef,  \%options);

#  $values_list = $rep->get_values_list ($table, $key,     \@cols, \%options);
#  $values_list = $rep->get_values_list ($table, \%params, \@cols, \%options);
#  $values_list = $rep->get_values_list ($table, $key,     undef,  \%options);
#  $values_list = $rep->get_values_list ($table, \%params, undef,  \%options);

#  $rep->set_values ($table, $key,     \@cols, $values, \%options);
#  $rep->set_values ($table, $key,     undef,  $values, \%options);
#  $rep->set_values ($table, undef,    \@cols, $values, \%options);
#  $rep->set_values ($table, undef,    undef,  $values, \%options);
#  $rep->set_values ($table, \%params, \@cols, $values, \%options);
#  $rep->set_values ($table, \%params, undef,  $values, \%options);

{
    my $dbh = $rep->{dbh};
    $dbh->do("drop table test_person");
}

exit 0;

