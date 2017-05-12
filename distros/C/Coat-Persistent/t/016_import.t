use strict;
use warnings;
use Test::More 'no_plan';

BEGIN { 
    use_ok 'Coat::Persistent';
    use_ok 'Coat::Persistent::Meta'; 
}

{
    package Person;
    use Coat;
    use Coat::Persistent 
        table_name => 'people', 
        primary_key => 'people_id';

    has_one 'Car';
    has_many  'Friend';

    has_p 'name' => (isa => 'Str');
    has_p 'age' => (isa => 'Int');

    package Friend;
    use Coat;
    use Coat::Persistent 
        table_name => 'amis', 
        primary_key => 'f_id';
    extends 'Person';

    has_p nickname => (isa => 'Str', default => 'dude');

    package Car;
    use Coat;
    use Coat::Persistent 
        table_name => 'voiture', 
        primary_key => 'c_id';

    has_p 'max_speed' => (isa => 'Int');
    has_p 'color' => (isa => 'Str');

    Coat::Persistent->map_to_dbi('csv', 'f_dir=./t/csv-test-database');
}

# fixture
my $dbh = Person->dbh;
$dbh->do("CREATE TABLE people (people_id INTEGER, name CHAR(64), age INTEGER, voiture_c_id INTEGER)");
$dbh->do("CREATE TABLE amis (f_id INTEGER, people_people_id INTEGER, name CHAR(64), age INTEGER, nickname CHAR(64))");
$dbh->do("CREATE TABLE voiture (c_id INTEGER, color CHAR(64), max_speed INTEGER)");

# TESTS 
is( 'people', Coat::Persistent::Meta->table_name('Person'), 'good table_name' );
is( 'people_id', Coat::Persistent::Meta->primary_key( 'Person'), 'good primary_key' );

my $p = Person->create( name => 'John' );
is( $p->people_id, 1, 'primary_key people_id is set' );
is( $p->name, 'John', 'name is set' );

$p = Person->find_by_name( 'John' );
ok( defined $p, 'find_by_name works' );

$p = Person->find( 1 );
ok( defined $p, 'find works' );

$p->name('David');
ok( $p->save, 'name changed' );
$p = Person->find( 1 );
is( 'David', $p->name, 'name is David' );

my $car = Car->create( color => 'red', max_speed => 180 );
ok( defined $car, 'car created' );

ok( $p->voiture( $car ), 'set the car to $p' );
my $c2 = $p->voiture;
is( $car->c_id, $c2->c_id, '$p->voiture returns $car' );

# remove the test db
$dbh->do("DROP TABLE people");
$dbh->do("DROP TABLE amis");
$dbh->do("DROP TABLE voiture");
$dbh->do("DROP TABLE dbix_sequence_state");
$dbh->do("DROP TABLE dbix_sequence_release");
