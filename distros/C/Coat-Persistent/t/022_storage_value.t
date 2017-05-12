use strict;
use warnings;
use Test::More 'no_plan';

BEGIN { use_ok 'Coat::Persistent' }
    

{
    package Person;
    use Coat;
    use Coat::Persistent table_name => 'people', primary_key => 'pid';
    use Coat::Persistent::Types::MySQL;

    has_p 'name' => (isa => 'Str');
    has_p 'age' => (isa => 'Int');

    has_p 'created_at' => (
        is => 'rw',
        isa => 'UnixTimestamp',
        store_as => 'MySQL:DateTime',
    );

    has_p 'birth_date' => (
        is => 'rw',
        isa => 'UnixTimestamp',
        store_as => 'MySQL:Date',
    );
}


# fixture
Coat::Persistent->map_to_dbi('csv', 'f_dir=./t/csv-test-database');

my $dbh = Person->dbh;
$dbh->do("CREATE TABLE people (pid INTEGER, birth_date CHAR(4), name CHAR(64), age INTEGER, created_at CHAR(30))");

# TESTS 

my $t = time;
my $joe = Person->new( 
    name => 'Joe', 
    age => 21, 
    created_at => $t,
    birth_date => '1983-02-06');

my $t_str = $joe->get_storage_value_for('created_at');

is($t, $joe->created_at, "created_at is an int : $t ");
ok($t ne $t_str, "created_at storage value is : $t_str");
ok($joe->save, '$joe->save');

my $joe2 = Person->find($joe->pid);
is($joe2->created_at, $t, 'created_at is still an Int when fetched');
ok($joe2->created_at(time() + 3600), 'we can play with numbers in created_at');
ok($joe2->save, '$joe->save');

ok($joe2->birth_date('1979-11-20'), 'birth_date set with a Date');
ok($joe2->save, '$joe2->save');
ok($joe2->birth_date ne '1979-11-20', 'birth_date was coerced: '.$joe2->birth_date);

$dbh->do("DROP TABLE people");
