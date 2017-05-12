use strict;
use warnings;
use Test::More 'no_plan';

BEGIN { use_ok 'Coat::Persistent' }

# must have Cache::FastMmap isntalled
eval "use Cache::FastMmap";
my $have_cache_fastmmap = ($@ ? 0 : 1);

SKIP: {
     skip "Cache::FastMmap not installed", 10 unless $have_cache_fastmmap;
{
    package Person;
    use Coat;
    use Coat::Persistent;

    has_p 'name' => (isa => 'Str');
    has_p 'age' => (isa => 'Int');

    __PACKAGE__->map_to_dbi('csv', 'f_dir=./t/csv-test-database');
    __PACKAGE__->enable_cache(share_file => './t/cache.map');
}

# fixture
my $dbh = Person->dbh;
$dbh->do("CREATE TABLE person (id INTEGER, name CHAR(64), age INTEGER)");

# TESTS 

ok( -f './t/cache.map', 'cache file exists' );

my $p1 = new Person name => 'John', age => 22;
$p1->save;
my $p2 = Person->find($p1->id);
is( $p2->name, $p1->name, '$p1 and $p2 are the same' );

$p1->name('Bob');
$p1->save;

my $p3 = Person->find($p1->id);
is($p2->name, $p3->name, '$p3 and $p2 are the same : name didn\'t change' );

Person->disable_cache;

$p3 = Person->find($p1->id);
is($p1->name, $p3->name, '$p1 and $p3 are the same : name changed' );

$dbh->do("DROP TABLE person");
$dbh->do("DROP TABLE dbix_sequence_state");
$dbh->do("DROP TABLE dbix_sequence_release");
};
