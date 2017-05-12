use strict;
use warnings;
use Test::More 'no_plan';

BEGIN { use_ok 'Coat::Persistent' }
    
use Coat::Types;

enum 'Sex' => 'Male', 'Female', '';

{
    package Person;
    use Coat;
    use Coat::Persistent table_name => 'people';

    has_p 'name' => (isa => 'Str');
    has_p 'age' => (isa => 'Int');
    has_p sex => (isa => 'Sex');

    has_many 'dogs', 
        class_name => 'Dog';

    package Dog;
    use Coat;
    use Coat::Persistent
        table_name => 'dogs';


    has_p name => (isa => 'Str');
    has_p colour => (isa => 'Str');
    has_p sex => (isa => 'Sex');

    has_one 'master', 
        class_name => 'Person';
}


# fixture
Coat::Persistent->map_to_dbi('csv', 'f_dir=./t/csv-test-database');

my $dbh = Person->dbh;
$dbh->do("CREATE TABLE people (id INTEGER, sex CHAR(64), name CHAR(64), age INTEGER)");
$dbh->do("CREATE TABLE dogs (id INTEGER, sex CHAR(64), name CHAR(64), colour CHAR(64), people_id INTEGER)");

# TESTS 

my $joe = Person->new( name => 'Joe', age => 21 );
ok( $joe->save, '$p->save' );

my @dogs;
foreach my $dog_name (qw(medor rintintin pif)) {
    my $d = Dog->new( name => 'medor', colour => 'white', sex => 'Male', master => $joe);
    ok( $d->save, "\$$dog_name->save" );
    push @dogs, $d;
}

ok( $joe->dogs( @dogs ), '$joe->dogs( @dogs )' );
ok( $joe->save, '$joe->save' );

@dogs = Dog->find();
is( $joe->id, $dogs[0]->people_id, '$dog->people_id is set' );

@dogs = $joe->dogs;
ok( @dogs == 3, '$joe->dogs' );

is( $dogs[0]->name, 'medor', 'medor is the first dog of joe' );
is( $joe->id, $dogs[2]->master->id, 'joe is the master of third dog' );

# remove the test db
$dbh->do("DROP TABLE people");
$dbh->do("DROP TABLE dogs");
$dbh->do("DROP TABLE dbix_sequence_state");
$dbh->do("DROP TABLE dbix_sequence_release");

