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
# Person->map_to_dbi('mysql' => 'coat', 'dbuser' => 'dbpass');

# fixture
my $dbh = Person->dbh;
$dbh->do("CREATE TABLE person (id INTEGER, name CHAR(64), age INTEGER)");
foreach my $name ('Joe', 'John', 'Brenda') {
    my $p = new Person name => $name, age => 20;
    $p->save;
}

# tests
my @people = Person->find_by_sql("select * from person where name like 'Jo%'");
is(@people, 2, 'find_by_sql returned 2 objects');
isa_ok($people[0], 'Person', 'first one');
isa_ok($people[1], 'Person', 'second');

my @list = Person->find( "name like 'Jo%'" );
is_deeply(\@list, \@people, 'find with condition in list context');

if (Person->driver eq 'mysql') {
    @people = Person->find_by_sql("select count(*) as count, person.* "
                                    ."from person "
                                    ."where age = ? "
                                    ."group by age", 20);
    is(@people, 1, 'only 1 object returned with group by age');
    isa_ok($people[0], 'Person');
    ok(defined $people[0]->{count}, "object has pseudo attr 'count'");
    is($people[0]->{count}, 3, 'count == 3');
    is($people[0]->age, 20, 'age == 20' );
}

# remove the test db
$dbh->do("DROP TABLE person");
$dbh->do("DROP TABLE dbix_sequence_state");
$dbh->do("DROP TABLE dbix_sequence_release");
