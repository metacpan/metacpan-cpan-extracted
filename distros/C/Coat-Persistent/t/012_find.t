use strict;
use warnings;
use Test::More tests => 10;

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
Person->create([
    { name => 'Brenda', age => 31 }, 
    { name => 'Nate', age => 34 }, 
    { name => 'Dave', age => 29 }
]);

# test the find with a list of IDs
my ($brenda, $nate, $dave) = Person->find(1, 2, 3);

ok( defined $brenda, 'defined $brenda' );
ok( defined $dave, 'defined $dave' );
ok( defined $nate, 'defined $nate' );

# find() with options...

# order
my @sorted_names = sort qw(Brenda Nate Dave);
my @people = Person->find({ order => 'name' });
is( 3, @people, '3 people returned' );
is_deeply (\@sorted_names, [ map { $_->name } @people], 'names are sorted');

# limit
@people = Person->find(["id > ?", 0], { limit => 2, order => 'name' });
is( 2, @people, '2 people returned' );

# select
my $brend = Person->find("name = 'Brenda'", {select => 'name'});
ok( defined $brend, '$brend defined');
is( 'Brenda', $brend->name, 'name is set' );
ok( ! defined $brend->age, 'age is not set' );

# remove the test db
$dbh->do("DROP TABLE person");
$dbh->do("DROP TABLE dbix_sequence_state");
$dbh->do("DROP TABLE dbix_sequence_release");
