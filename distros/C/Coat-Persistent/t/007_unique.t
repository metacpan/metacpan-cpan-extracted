use strict;
use warnings;
use Test::More 'no_plan';

BEGIN { use_ok 'Coat::Persistent' }
{
    package Person;
    use Coat;
    use Coat::Persistent;
    has_p name => (isa => 'Str', unique => 1);
    has_p age  => (isa => 'Int');
}

Person->map_to_dbi('csv', 'f_dir=./t/csv-test-database');


# fixture
my $dbh = Person->dbh;
$dbh->do("CREATE TABLE person (id INTEGER, name CHAR(64), age INTEGER)");
foreach my $name ('MisterJoe', 'MisterJohn', 'MissBrenda') {
    my $p = new Person name => $name, age => 20;
    $p->save;
}

# tests
my $p;
eval {
    $p = Person->new(name => 'MisterJoe'); 
    $p->save;
};
ok( $@, "Value MisterJoe violates unique constraint for attribute name");

# clean
$dbh->do("DROP TABLE person");
$dbh->do("DROP TABLE dbix_sequence_state");
$dbh->do("DROP TABLE dbix_sequence_release");
