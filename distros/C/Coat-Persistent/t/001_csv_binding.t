use strict;
use warnings;
use Test::More tests => 19;

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

my @fields = sort keys %{ Coat::Meta->all_attributes( 'Person' ) };
my @expected = sort qw(id name age);

is_deeply(\@fields, \@expected, 'attributes look good (with id)');

my $john = new Person name => "John", age => 23;
isa_ok($john, 'Coat::Object');
isa_ok($john, 'Coat::Persistent');
isa_ok($john, 'Person');

ok( ! defined $john->id, '$john->id is not defined' );
ok( $john->save, '$john->save' );
is( $john->id, 1, '$john->id is equal to 1' );

my $brenda = new Person name => "Brenda", age => 22;
ok(! defined $brenda->id, '$brenda->id not defined' );
ok( $brenda->save, '$brenda->save' );
is( $brenda->id, 2, '$brenda->id is equal to 2' );

my $p = Person->find(1);
ok( defined $p, 'Person->find(1) returned something' );
isa_ok( $p, 'Person' );
isa_ok( $p, 'Coat::Persistent' );
isa_ok( $p, 'Coat::Object' );

$p = Person->find_by_name('Brenda');
ok( defined $p, 'Person->find_by_name returned something' );
isa_ok( $p, 'Person' );
is( $p->name, $brenda->name, '$p is equal to $brenda' );

ok( $brenda->delete, '$brenda->delete' );

# remove the test db
$dbh->do("DROP TABLE person");
$dbh->do("DROP TABLE dbix_sequence_state");
$dbh->do("DROP TABLE dbix_sequence_release");
