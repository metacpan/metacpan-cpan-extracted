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

# should work with only a value
my $joe1 = Person->find_or_create_by_name('Joe');
ok( defined $joe1, 'defined $joe1' );
ok( ! defined $joe1->age, '$joe1->age is not defined' );

my $joe2 = Person->find_or_create_by_name('Joe');
ok( defined $joe2, 'defined $joe2' );
is( $joe1->id, $joe2->id, '$joe1 == $joe2' );

# should work with a full attr-hash
my $tom1 = Person->find_or_create_by_name(name => 'Tom', age => 42);
ok( defined $tom1, 'defined $tom1' );
is( 42, $tom1->age, '$tom1->age == 42' );

my $tom2 = Person->find_or_create_by_name(name => 'Tom', age => 42);
ok( defined $tom2, 'defined $tom2' );
is( $tom1->id, $tom2->id, '$tom1 == $tom2' );

# should not work if the attr is omited
eval {
    Person->find_or_create_by_name(age => 42);
};
ok( $@, 'unable to create without name' );

# remove the test db
$dbh->do("DROP TABLE person");
$dbh->do("DROP TABLE dbix_sequence_state");
$dbh->do("DROP TABLE dbix_sequence_release");
