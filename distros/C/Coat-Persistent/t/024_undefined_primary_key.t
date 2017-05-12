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
        primary_key => undef;

    has_p 'people_id' => (isa => 'Int');
    has_p 'name' => (isa => 'Str');

    Coat::Persistent->map_to_dbi('csv', 'f_dir=./t/csv-test-database');
}

# fixture
my $dbh = Person->dbh;
$dbh->do("CREATE TABLE people (people_id INTEGER, name CHAR(64))");

# TESTS 

is(Coat::Persistent::Meta->primary_key( 'Person'), undef, 'primary_key is undefined');

my $p = Person->create( people_id => 42, name => 'John' );
is( $p->people_id, 42, 'people_id is set to 42' );
is( $p->name, 'John', 'name is set' );

$p = Person->find_by_name( 'John' );
ok( defined $p, 'find_by_name works' );

eval { $p = Person->find( 1 ) };
ok( $@, 'unable to find with ID');

ok( Person->find_by_people_id(42), 'find_by_attr works');
ok( Person->find("name = 'John'"), 'find with an SQL condition works');

$p->name('Chuck Norris');
ok( $p->save({ people_id => 42}), 'save works with a condtion and no primary_key');

my $x = Person->find_by_people_id(42);
is($x->name, 'Chuck Norris', 'name has been changed in database');

# remove the test db
$dbh->do("DROP TABLE people");
$dbh->do("DROP TABLE dbix_sequence_state");
$dbh->do("DROP TABLE dbix_sequence_release");
