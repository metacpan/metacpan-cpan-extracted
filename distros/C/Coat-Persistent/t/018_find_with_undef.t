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
# Person->map_to_dbi('mysql' => 'coat', 'dbuser' => 'dbpass');

# fixture
my $dbh = Person->dbh;
$dbh->do("CREATE TABLE person (id INTEGER, name CHAR(64), age INTEGER, nickname CHAR(64), secondname CHAR(64))");
Person->create([
    { name => 'John', age => 20, nickname => 'Johnny' },
    { name => 'Brenda', age => 20 },
]);
$dbh->do("UPDATE person SET secondname='Junior' WHERE name='John'");

# test the find with a list of IDs
my ($john, $brenda) = Person->find(1, 2);

print $brenda->dump;
exit;

is($john->nickname, 'Johnny', 'nickname set');
is($brenda->nickname, undef, 'nickname not set');
# since secondname is not Coat-declared I have to access the variable directly, not with method
is($john->{secondname}, 'Junior', 'second name(not Coat-declared) set');
is($brenda->{secondname}, undef, 'second name(not Coat-declared) not set');


# remove the test db
$dbh->do("DROP TABLE person");
$dbh->do("DROP TABLE dbix_sequence_state");
$dbh->do("DROP TABLE dbix_sequence_release");
