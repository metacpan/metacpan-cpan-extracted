use strict;
use warnings;
use Test::More tests => 2;

BEGIN { use_ok 'Coat::Persistent' }
{
    package Person;
    use Coat;
    use Coat::Persistent;
    has_p name => (isa => 'Str', required => 1, is => 'ro');
    has_p age  => (isa => 'Int');
}

Person->map_to_dbi('csv', 'f_dir=./t/csv-test-database');

# fixture
my $dbh = Person->dbh;
$dbh->do("CREATE TABLE person (id INTEGER, name CHAR(64), age INTEGER)");
foreach my $name ('Joe', 'John', 'Brenda') {
    my $p = new Person name => $name, age => 20;
    $p->save;
}

# test
my $p = Person->find(1);
ok( defined $p, '$p is found' );

# clean
$dbh->do("DROP TABLE person");
$dbh->do("DROP TABLE dbix_sequence_state");
$dbh->do("DROP TABLE dbix_sequence_release");
