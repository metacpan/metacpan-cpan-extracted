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
my $p = new Person name => 'Dude', age => 23;
ok( $p->save, '$p->save' );
is( 'Dude', $p->name, 'name eq Dude' );
ok( $p->name('Bob'), '$p->name(Bob)' );
ok( $p->save, '$p->save' );

my $p2 = Person->find($p->id);
is($p->id, $p2->id, '$p and $p2 have the same id' );
is( 'Bob', $p2->name, 'name is Bob' );

# remove the test db
$dbh->do("DROP TABLE person");
$dbh->do("DROP TABLE dbix_sequence_state");
$dbh->do("DROP TABLE dbix_sequence_release");
