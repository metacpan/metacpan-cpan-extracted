#!/usr/bin/perl

use strict;
use Test::More;
use DBI;

# use warnings;
# use Data::Dumper;

# $Class::Tables::SQL_DEBUG++;

############################
## get DB connection info ##
############################

my %drivers = (
    mysql  => {
        show => "show tables",
        pkey => "int primary key not null auto_increment",
        blob => "blob"
    },
    SQLite => {
        show => "select name from sqlite_master where type='table'",
        pkey => "integer primary key",
        blob => "blob"
    },
    Pg => {
        show => "select tablename from pg_tables where schemaname='public'",
        pkey => "serial primary key",
        blob => "bytea"
    }
);

use lib 'testconfig';
my $Config;
eval q[
    use Class::Tables::TestConfig;
    $Config = Class::Tables::TestConfig->Config;
];

###################
## DB connection ##
###################

if ($Config->{dsn} =~ /^skip$/i) {
    plan skip_all => "User has skipped the test suite. Run `perl Makefile.PL "
                   . "-s` to reconfigure the connection parameters for the "
		   . "test database.";
}

my $dbh = eval {
    DBI->connect( @$Config{qw/dsn user password/}, 
                  { RaiseError => 0, PrintError => 0 } )
};

if (not $dbh) {
    plan skip_all => "Couldn't connect to the database for testing. Run `perl "
                   . "Makefile.PL -s` to reconfigure the connection parameters "
		   . "for the test database.";

} elsif ( ! $drivers{ $dbh->{Driver}{Name} } ) {
    $dbh->disconnect;
    my $drivers = join " " => sort keys %drivers;
    
    plan skip_all => "Your database driver is not supported (supported: "
                   . "$drivers). Run `perl Makefile.PL -s` to reconfigure "
		   . "the connection parameters for the test database.";

} else {
    plan tests => 70;
    diag "Starting test suite. Run `perl Makefile.PL -s` to reconfigure "
       . "connection parameters for the test database.";
}

## clear all tables first

my $driver = $dbh->{Driver}{Name};

my $q = $dbh->prepare( $drivers{$driver}{show} );
$q->execute;
while ( my ($table) = $q->fetchrow_array ) {
    diag "DROPPING $table";
    $dbh->do("drop table $table");
}
$q->finish;

######################
## insert test data ##
######################

my $pkey = $drivers{$driver}{pkey};
my $blob = $drivers{$driver}{blob};

$dbh->do($_) for (split /\s*;\s*/, <<"END_OF_SQL");

    create table departments (
        id              $pkey,
        name            varchar(50) not null,
        ends_with_id    integer
    );
    create table employees (
        id              $pkey,
        employee_name   varchar(50) not null unique,
        department_id   integer,
        employees_photo $blob
    );
    create table purchases (
        purchase_id          $pkey,
        purchase_product     integer not null,
        purchase_employee_id integer not null,
        purchase_quantity    integer not null,
        purchases_date       date,
        purchase_foo_id      integer
    );
    create table products (
        id              $pkey,
        name            varchar(50) not null,
        weight          integer,
        price           decimal
    );
    
    insert into departments (name,ends_with_id)
        values ('Hobbiton Division',0);
    insert into departments (name,ends_with_id)
        values ('Bree Division',0);
    insert into departments (name,ends_with_id)
        values ('Buckland Division',0);
    insert into departments (name,ends_with_id)
        values ('Michel Delving Division',0);
    
    insert into employees (employee_name,department_id)
        values ('Frodo Baggins',3);
    insert into employees (employee_name,department_id)
        values ('Bilbo Baggins',3);
    insert into employees (employee_name,department_id)
        values ('Samwise Gamgee',3);
    insert into employees (employee_name,department_id)
        values ('Perigrin Took',2);
    insert into employees (employee_name,department_id)
        values ('Fredegar Bolger',2);
    insert into employees (employee_name,department_id)
        values ('Meriadoc Brandybuck',2);
    insert into employees (employee_name,department_id)
        values ('Lotho Sackville-Baggins',4);
    insert into employees (employee_name,department_id)
        values ('Ted Sandyman',4);
    insert into employees (employee_name,department_id)
        values ('Will Whitfoot',4);
    insert into employees (employee_name,department_id)
        values ('Bandobras Took',1);
    insert into employees (employee_name,department_id)
        values ('Folco Boffin',1);
        
    insert into products (name,weight,price)
        values ('Southfarthing Pipeweed',10,200);
    insert into products (name,weight,price)
        values ('Prancing Pony Ale',150,300);
    insert into products (name,weight,price)
        values ('Farmer Cotton Mushrooms',200,150);
    insert into products (name,weight,price)
        values ('Green Dragon Ale',150,350);
    
    insert into purchases
        (purchase_product,purchase_employee_id,purchase_quantity,purchases_date)
        values (2,6,6,'2002-12-10');
    insert into purchases
        (purchase_product,purchase_employee_id,purchase_quantity,purchases_date)
        values (4,3,1,'2002-12-10');
    insert into purchases
        (purchase_product,purchase_employee_id,purchase_quantity,purchases_date)
        values (1,2,20,'2002-12-09');
    insert into purchases
        (purchase_product,purchase_employee_id,purchase_quantity,purchases_date)
        values (3,4,8,'2002-12-11');
    insert into purchases
        (purchase_product,purchase_employee_id,purchase_quantity,purchases_date)
        values (1,1,1,'2002-12-13');
    insert into purchases
        (purchase_product,purchase_employee_id,purchase_quantity,purchases_date)
        values (3,1,2,'2002-12-15');
    insert into purchases
        (purchase_product,purchase_employee_id,purchase_quantity,purchases_date)
        values (3,3,3,'2002-12-12');
    insert into purchases
        (purchase_product,purchase_employee_id,purchase_quantity,purchases_date)
        values (3,3,15,'2002-12-08');
    insert into purchases
        (purchase_product,purchase_employee_id,purchase_quantity,purchases_date)
        values (2,6,11,'2002-12-08');
    insert into purchases
        (purchase_product,purchase_employee_id,purchase_quantity,purchases_date)
        values (3,2,8,'2002-12-14')

END_OF_SQL

####################
## initialization ##
####################

my $timer = times;

use_ok('Class::Tables');

{
    package MySubclass;
    our @ISA = ('Class::Tables');
    our $hello = 0;
    sub search {
        my $x = shift;
        $hello++;
        $x->SUPER::search(@_);
    }
}

MySubclass->dbh($dbh);

# use Data::Dumper;
# print Dumper \%Class::Tables::CLASS;

#################
## subclassing ##
#################

my @classes = qw/Employees Departments Products Purchases/;

for (@classes) {
    no strict 'refs';
    is_deeply(
        \@{"$_\::ISA"},
        ['MySubclass'],
        "$_ class created w/ proper \@ISA" );
}

########################
## fetch class method ##
########################

for (@classes) {
    isa_ok(
        $_->fetch(1),
        $_,
        "$_->fetch" );
}

is( Employees->fetch(234332),
    undef,
    "fetch returns undef on failure" );

#########################
## search class method ##
#########################

is( Employees->search(id => 1)->id,
    Employees->fetch(1)->id,
    "search on id is equivalent to fetch" );

my @emps = Employees->search;

ok( scalar @emps,
    "search with no args" );

is_deeply(
    [ grep { ! $_->isa("Employees") } @emps ],
    [],
    "search returns Employees objects" );

is( join(":" => sort { $emps[$a]->name cmp $emps[$b]->name } 0 .. $#emps),
    join(":" => 0 .. $#emps),
    "search results sorted" );

is( scalar Employees->search(name => "asdfasdfasdf"),
    undef,
    "search returns undef on failure" );

is_deeply(
    [ Employees->search(name => "asdfasdfasdf") ],
    [],
    "search returns empty list on failure" );

isa_ok(
    scalar Employees->search( name => "Frodo Baggins" ),
    "Employees",
    "search result" );

is( Employees->search( name => "Frodo Baggins" )->name,
    "Frodo Baggins",
    "search result consistent" );

ok( scalar Employees->search(department => Departments->fetch(3)),
    "search with object constraint on foreign key" );

########################
## instance accessors ##
########################

my %simple_accessors = (
    Departments => {
        id           => '',
        name         => '',
        ends_with_id => '',
        employees    => "Employees" # x
    },
    Employees => {
        id           => '',
        name         => '',
        department   => "Departments",
        photo        => '',
        purchases    => "Purchases" # x
    },
    Purchases => {
        id          => '',
        product     => "Products",
        employee    => "Employees",
        quantity    => '',
        date        => '',
        foo_id      => '',
    },
    Products => {
        id          => '',
        name        => '',
        weight      => '',
        price       => '',
        purchases   => "Purchases" # x
    }
);

my $field_ok = 1;

for my $class (keys %simple_accessors) {
    my $obj = $class->fetch(1);

    my @supposed_accessors = $obj->field;

    @supposed_accessors == @{[ keys %{ $simple_accessors{$class} } ]}
        or $field_ok = 0;

    for (@supposed_accessors) {
        exists $simple_accessors{$class}{$_} or $field_ok = 0;
    }

    for my $accessor (keys %{ $simple_accessors{$class} }) {
        is( ref $obj->$accessor,
            $simple_accessors{$class}{$accessor},
            "correct $class\->$accessor accessor" );
    }
}

ok( $field_ok,
    "field() accessor with no args" );

####

my $h = Employees->fetch(1);

is( "$h",
    $h->name,
    "objects stringify to name column" );

ok( scalar(() = $h->purchases) > 1,
    "indirect foreign key returns list" );

ok( do { eval { $h->age }; $@ },
    "die on bad accessor name" );

my $old_id = $h->id;
is( do { eval { $h->id(5) }; $h->id },
    $old_id,
    "id accessor read-only" );

my $new_guy = Employees->fetch(3);
my $count = $Class::Tables::SQL_QUERIES;
(undef) = $new_guy->photo;
ok( $count < $Class::Tables::SQL_QUERIES,
    "blob accessors lazy-loaded" );

my @p1 = $h->purchases;
my @p2 = $h->purchases(product => 3);
ok( @p1 > @p2,
    "additional search constraints in indirect key accessors" );

##############################
## object instance mutators ##
##############################

my $dept = Departments->fetch(1);
$h->department($dept);

is( $h->department->id,
    $dept->id,
    "change foreign key correctly using object" );

$h->name("Frodo Nine-Fingers");

is( $h->name,
    "Frodo Nine-Fingers",
    "change normal column correctly" );

$h->department( $dept->id );

isa_ok(
    $h->department,
    "Departments",
    "change foreign key with id only" );

ok( scalar Employees->search(name => "Frodo Nine-Fingers", department => $dept),
    "changes visible in database" );

$h->department(0);
is( $h->department,
    undef,
    "dangling foreign key accessors return undef" );

$h->department($dept);

## 
#$h->department("asdfasdf");
#is( $h->department,
#    $dept,
#    "gracefully handle invalid keys" );
#$h->department( $dept );

#################
## concurrency ##
#################

my $p1 = Purchases->fetch(1);
my $p2 = Purchases->fetch(1);
$p1->quantity(1);
$p2->quantity(99999);

is( $p2->quantity,
    $p1->quantity,
    "updates concurrently visible" );

######################
## creating objects ##
######################

is( Employees->new(name => "Samwise Gamgee"),
    undef,
    "new returns undef on failure" );

my $new = Employees->new(name => "Grima Wormtongue", department => $dept);

isa_ok(
    $new,
    "Employees",
    "new return value" );

ok( defined $new->id,
    "got insert ID for new object" );

is( $new->name,
    "Grima Wormtongue",
    "new creates object with initial info" );

is( $new->department->id,
    $dept->id,
    "new creates object using object for foreign key" );

##########################
## dump instance method ##
##########################

my $dump = $h->dump;

isa_ok(
    $dump,
    "HASH",
    "dump output" );

is( $dump->{'department.name'},
    $h->department->name,
    "dump output foreign keys inflated" );

isa_ok(
    $dump->{purchases},
    "ARRAY",
    "dump output indirect foreign key" );

is( $dump->{purchases}[0]{'product.name'},
    ($h->purchases)[0]->product->name,
    "dump output indirect foreign keys inflated" );

######################
## deleting objects ##
######################

my $id = $new->id;
$new->delete;

is( Employees->fetch($id),
    undef,
    "delete from database" );

@p1 = Purchases->search;
my $num = grep { $_->employee->id == 3 } @p1;

Employees->fetch(3)->delete;
is( scalar Purchases->search(employee => 3),
    undef,
    "cascading deletes turned on" );

@p2 = Purchases->search;
is( scalar @p1 - $num,
    scalar @p2,
    "cascading deletes leave the rest" );

{
    local $Class::Tables::CASCADE = 0;

    Employees->fetch(2)->delete;
    isnt(
        scalar Purchases->search(employee => 2),
        undef,
        "cascading deletes turned off" );
}

$_->delete for Employees->search;

is( scalar Employees->search,
    undef,
    "delete all in a table" );

#######################
## undef/null values ##
#######################

{
    my $prod = Products->fetch(4);
    $prod->weight(undef);

    my $ar = $dbh->selectall_arrayref("select weight from products where id=4");
    
    ok( exists $ar->[0][0] && ! defined $ar->[0][0],
        "undef becomes NULL in database" );

}

## flyweight object goes out of scope, so next line must query the database

ok( ! defined Products->fetch(4)->weight,
    "NULL database values come back undef" );

is( scalar( () = Products->search( weight => undef ) ),
    1,
    "search method handles searching with IS NULL" );

###########################
## subclassing revisited ##
###########################

isnt(
    $MySubclass::hello,
    0,
    "subclass overrides methods" );

## done!

$timer = times - $timer;
diag "SUMMARY: $Class::Tables::SQL_QUERIES queries, ${timer}s (using $driver)";

#############
## cleanup ##
#############

END {
    if ($dbh and $dbh->{Active}) {
        $dbh->do($_) for (split /\s*;\s*/, <<'        END_OF_SQL');
            drop table /*! if exists */ departments;
            drop table /*! if exists */ employees;
            drop table /*! if exists */ products;
            drop table /*! if exists */ purchases
        END_OF_SQL

        $dbh->disconnect;
    }
}
