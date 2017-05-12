use strict;
use warnings;
use Test::More 'no_plan';

BEGIN { use_ok 'Coat::Persistent' }

{
    package Person;
    use Coat;
    use Coat::Persistent;

    has_p 'name' => (isa => 'Str');
    has_p 'age' => (isa => 'Int');

    __PACKAGE__->map_to_dbi('csv', 'f_dir=./t/csv-test-database');
}

# fixture
my $dbh = Person->dbh;
$dbh->do("CREATE TABLE person (id INTEGER, name CHAR(64), age INTEGER)");

# TESTS 
my $p1 = Person->create(name => 'John', age => 23);
ok( defined $p1->id, 'defined $p1->id' );
$p1 = Person->find($p1->id);
ok( defined $p1->id, 'defined $p1->id (retreived with find)' );


Person->create([
    { name => 'Brenda', age => 31 }, 
    { name => 'Nate', age => 34 }, 
    { name => 'Dave', age => 29 }
]);

my $brenda = Person->find_by_name('Brenda');
my $nate = Person->find_by_name('Nate');
my $dave = Person->find_by_name('Dave');

ok( defined $brenda, 'defined $brenda' );
ok( defined $dave, 'defined $dave' );
ok( defined $nate, 'defined $nate' );

# remove the test db
$dbh->do("DROP TABLE person");
$dbh->do("DROP TABLE dbix_sequence_state");
$dbh->do("DROP TABLE dbix_sequence_release");
