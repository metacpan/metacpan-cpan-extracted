use strict;
use warnings;
use Test::More 'no_plan';

BEGIN { use_ok 'Coat::Persistent' }
{
    package Person;
    use Coat;
    use Coat::Persistent;
    has_p name => (isa => 'Str');
    has_p age  => (isa => 'Int');
    has_p nickname  => (is => 'rw',isa => 'Str');
}

Person->map_to_dbi('csv', 'f_dir=./t/csv-test-database');

# fixture
my $dbh = Person->dbh;
$dbh->do("CREATE TABLE person (id INTEGER, name CHAR(64), age INTEGER, nickname CHAR(64), secondname CHAR(64))");

# tests
my $john = Person->create(name => 'John');
is( Coat::Persistent::CP_ENTRY_EXISTS, $john->_db_state, 'CP_ENTRY_EXISTS on create');

my $john2 = Person->find($john->id);
ok( defined $john2, 'create worked' );
is( Coat::Persistent::CP_ENTRY_EXISTS, $john2->_db_state, 'CP_ENTRY_EXISTS on find');

my $brenda = Person->new( name => 'Brenda' );
is(Coat::Persistent::CP_ENTRY_NEW, $brenda->_db_state, 'CP_ENTRY_NEW on new object' );

$brenda->id(4); # hey we change the primary key here, cannot work ! 
eval { $brenda->save; };
ok($@, 'cannot touch a newborn object id');

my $bob = Person->create(name => 'Bob');
ok($bob->id != $brenda->id, 'id are not messed');

# remove the test db
$dbh->do("DROP TABLE person");
$dbh->do("DROP TABLE dbix_sequence_state");
$dbh->do("DROP TABLE dbix_sequence_release");
