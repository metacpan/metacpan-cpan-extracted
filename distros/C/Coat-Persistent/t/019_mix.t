use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok 'Coat::Persistent' }

{
    package Person;
    use Coat;
    use Coat::Persistent;

    has_p 'name' => (isa => 'Str');
    has_p 'age' => (isa => 'Int');
    
    has abc => (isa => 'Str');

    sub BUILD {
        $_[0]->abc('123');
    }

    __PACKAGE__->map_to_dbi('csv', 'f_dir=./t/csv-test-database');
}

# fixture
my $dbh = Person->dbh;
$dbh->do("CREATE TABLE person (id INTEGER, name CHAR(64), age INTEGER)");

# TESTS 
Person->create([
    { name => 'Brenda', age => 31 }, 
]);

# test the find with a list of IDs
my ($brenda) = Person->find(1);

is( $brenda->abc, '123', 'on a 123');


ok( defined $brenda, 'defined $brenda' );

# remove the test db
$dbh->do("DROP TABLE person");
$dbh->do("DROP TABLE dbix_sequence_state");
$dbh->do("DROP TABLE dbix_sequence_release");
