use strict;
use warnings;
use Test::More tests => 9;

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
my $joe1 = Person->find_or_initialize_by_name('Joe');
ok( defined $joe1, 'defined $joe1' );
ok( ! defined $joe1->id, '$joe1->id is not defined' );

my $joe2 = Person->find_or_initialize_by_name('Joe');
ok( defined $joe2, 'defined $joe2' );
ok( ! defined $joe2->id, '$joe2->id is not defined' );

# should work with a full attr-hash
my $tom1 = Person->find_or_initialize_by_name(name => 'Tom', age => 42);
ok( defined $tom1, 'defined $tom1' );
ok( ! defined $tom1->id, '$tom1->id is not defined' );
is( 'Tom', $tom1->name, '$tom1->name == Tom' );

# should not work if the attr is omited
eval {
    Person->find_or_initialize_by_name(age => 42);
};
ok( $@, 'unable to initialize without name' );

# remove the test db
$dbh->do("DROP TABLE person");
$dbh->do("DROP TABLE dbix_sequence_state");
$dbh->do("DROP TABLE dbix_sequence_release");
