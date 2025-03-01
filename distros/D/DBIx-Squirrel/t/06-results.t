use strict;
use warnings;
use 5.010_001;

use Carp 'croak';
use Test::Warn;
use FindBin '$Bin';
use lib "$Bin/lib";

use Test::More;
#
# We use Test::More::UTF8 to enable UTF-8 on Test::Builder
# handles (failure_output, todo_output, and output) created
# by Test::More. Requires Test::Simple 1.302210+, and seems
# to eliminate the following error on some CPANTs builds:
#
# > Can't locate object method "e" via package "warnings"
#
use Test::More::UTF8;

BEGIN {
    use_ok( 'DBIx::Squirrel', database_entities => [qw(db artist artists)] )
        or print "Bail out!\n";
    use_ok( 'T::Squirrel', qw(:var diagdump) )
        or print "Bail out!\n";
}

diag join(
    ', ',
    "Testing DBIx::Squirrel $DBIx::Squirrel::VERSION",
    "Perl $]", "$^X",
);

# Filter out artists whose ArtistId is outside the 128...131 range.
sub filter { ( $_->[0] < 128 or $_->[0] > 131 ) ? () : $_ }

# Inject some additional (pending) results for the artist whose ArtistId is 128,
# else just return the artist's Name-field.
sub artist_name {
    ( $_->[0] == 128 ) ? ( $_->[1], 'Envy of None', 'Alex Lifeson' ) : $_->[1];
}

db( DBIx::Squirrel->connect(@TEST_DB_CONNECT_ARGS) );
artist( db->results('SELECT * FROM artists WHERE ArtistId=? LIMIT 1') );

my $private = artist->_private_state;

is_deeply $private->{bind_values_initial}, [], 'ok - bind_values_initial';
ok !exists( $private->{bind_values} ), 'ok - bind_values';
is_deeply $private->{transforms_initial}, [], 'ok - transforms_initial';
ok !exists( $private->{transforms} ), 'ok - transforms';

artist->iterate(128);

is_deeply $private->{bind_values_initial}, [],    'ok - bind_values_initial';
is_deeply $private->{bind_values},         [128], 'ok - bind_values';
is_deeply $private->{transforms_initial},  [],    'ok - transforms_initial';
is_deeply $private->{transforms},          [],    'ok - transforms';

artist->iterate(128)->next;

is_deeply $private->{bind_values_initial}, [],    'ok - bind_values_initial';
is_deeply $private->{bind_values},         [128], 'ok - bind_values';

# This test will exercise buffer control, transformations, pending results injection and
# results filtering.
artists( db->results(
    'SELECT * FROM artists ORDER BY ArtistId' => \&filter => \&artist_name,
) );

my $results  = artists->all;
my $expected = [
    'Rush', 'Envy of None', 'Alex Lifeson', 'Simply Red', 'Skank',
    'Smashing Pumpkins',
];

is_deeply(
    $results, $expected, 'ok - all (iteration, filtering, injection)',
);

# This test will exercise buffer control, transformations, pending results injection and
# results filtering.
$results  = artists->all;
$expected = [
    'Rush', 'Envy of None', 'Alex Lifeson', 'Simply Red', 'Skank',
    'Smashing Pumpkins',
];

is_deeply(
    $results, $expected, 'ok - all (iteration, filtering, injection ok)',
);

$private = artists->_private_state;

is $private->{cache_size_fixed}, !!0, 'artists->{cache_size_fixed}';
is(
    $private->{cache_size}, &DBIx::Squirrel::it::CACHE_SIZE_LIMIT,
    'ok - fixed cache size',
);

artists->cache_size(8)->execute;
$results = artists->all;

is_deeply $results, $expected, 'iteration, filtering, injection ok';
is $private->{cache_size_fixed}, !!1, 'artists->{cache_size_fixed}';
is $private->{cache_size},       8,   'artists->{cache_size}';

done_testing();
