use strict;
use warnings;
use Test::More 'no_plan';

BEGIN { use_ok 'Coat::Persistent' }
    

{
    package Person;
    use Coat;
    use Coat::Persistent table_name => 'people', primary_key => 'pid';
    use Coat::Persistent::Types::MySQL;

    has_p 'created_at' => (
        isa => 'UnixTimestamp',
        store_as => 'DateTime',
    );

    has_p updated_at => (
        isa => 'Class::Date',
        store_as => 'UnixTimestamp',
    );

    has_p 'birth_date' => (
        is => 'rw',
        isa => 'Date'
    );

    has_p date_as_time => (
        isa => 'DateTime',
        store_as => 'UnixTimestamp',
    );

    sub BUILD { shift->created_at(time) }
    before save => sub { shift->updated_at(time) };
}


# fixture
Coat::Persistent->map_to_dbi('csv', 'f_dir=./t/csv-test-database');

my $dbh = Person->dbh;
$dbh->do("CREATE TABLE people (pid INTEGER, birth_date CHAR(10), created_at CHAR(30), updated_at INTEGER, date_as_time INTEGER)");

# TESTS 

my $p = Person->new( birth_date => '1983-02-06' );
ok($p->save, '$p->save ');
ok($p->created_at, 'created_at is defined');
ok($p->updated_at, 'updated_at is defined');
ok($p->created_at =~ /^\d+$/, 'created_at is an UnixTimestamp');
is('Class::Date', ref $p->updated_at, 'updated_at is a Class::Date object');

my $created_at_storage = $p->get_storage_value_for('created_at');
my $updated_at_storage = $p->get_storage_value_for('updated_at');

ok($created_at_storage =~ /\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d/, 'created_at_storage is a DateTime');
ok($updated_at_storage =~ /^\d+$/, 'updated_at_storage is an UnixTimestamp');

is('1983-02-06', $p->birth_date, 'birth_date is unchanged');

# CLEAN
$dbh->do("DROP TABLE people");
