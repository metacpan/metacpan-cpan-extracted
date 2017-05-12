use strict;
use warnings;
use Test::More 'no_plan';

BEGIN { use_ok 'Coat::Persistent' }

{
    package Person;
    use Coat;
    use Coat::Persistent;

    has_one  'Avatar';
    has_many 'Car';

    has_p 'name' => (isa => 'Str');
    has_p 'age' => (isa => 'Int');

    package Avatar;
    use Coat;
    use Coat::Persistent;

    has_p 'imgpath' => (isa => 'Str');

    package Car;
    use Coat;
    use Coat::Persistent;

    has_one 'Person';
    has_p name => (isa => 'Str');
}

Coat::Persistent->map_to_dbi('csv', 'f_dir=./t/csv-test-database');
# Coat::Persistent->map_to_dbi('mysql' => 'coat', 'dbuser' => 'dbpass');

# fixture
my $dbh = Person->dbh;
$dbh->do("CREATE TABLE person (id INTEGER, avatar_id INTEGER, name CHAR(64), age INTEGER)");
$dbh->do("CREATE TABLE avatar (id INTEGER, imgpath CHAR(255))");
$dbh->do("CREATE TABLE car (id INTEGER, person_id INTEGER, name CHAR(255))");

my $a = new Avatar imgpath => '/tmp/toto.png';
$a->save;

my $bmw = new Car name => 'BMW';
$bmw->save;

my $ford = new Car name => 'Ford';
$ford->save;

my $nissan = new Car name => 'Nissan';
$nissan->save;

# TESTS 


my $p = new Person name => "Joe", age => 17;
ok( $p->save, '$p->save' );

ok( $p->avatar($a), '$p->avatar($a)' );
is( $p->avatar->id, $a->id, '$p->avatar->id == $a->id' );
is( $p->avatar_id, $a->id, '$p->avatar_id == $a->id');

ok( $p->save, '$p->save');

$p = Person->find($p->id);
ok( defined $p->avatar, '$p->avatar is defined after a find');
is( $p->avatar->id, $a->id, '$p->avatar->id == $a->id' );


$p->cars($bmw, $nissan, $ford);
ok( $p->save, '$p->save with cars');
my @cars = $p->cars;
is(@cars, 3, '3 cars returned by $p->cars');

eval { $p->cars($a) };
ok( $@, 'Cannot set something different from a Car to $p->cars ');

# remove the test db
$dbh->do("DROP TABLE person");
$dbh->do("DROP TABLE avatar");
$dbh->do("DROP TABLE car");
$dbh->do("DROP TABLE dbix_sequence_state");
$dbh->do("DROP TABLE dbix_sequence_release");
