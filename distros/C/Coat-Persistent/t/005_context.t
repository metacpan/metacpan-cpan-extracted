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
}

Person->map_to_dbi('csv', 'f_dir=./t/csv-test-database');

my $dbh = Person->dbh;
$dbh->do("CREATE TABLE person (id INTEGER, name CHAR(64), age INTEGER)");

foreach my $name ('Joe', 'John', 'Brenda') {
    my $p = new Person name => $name, age => 20;
    $p->save;
}

my @people = Person->find_by_age(20);
is(@people, 3, '3 items returned in list context');

my $person = Person->find_by_age(20);
isa_ok($person, 'Person', 'one Person returned in scalar context');

$dbh->do("drop table person");
$dbh->do("DROP TABLE dbix_sequence_state");
$dbh->do("DROP TABLE dbix_sequence_release");
