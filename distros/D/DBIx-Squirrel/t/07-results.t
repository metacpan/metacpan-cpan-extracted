use strict;
use warnings;
use open ':std', ':encoding(utf8)';
use Carp qw/croak/;
use Test::More;
use Test::Warn;
use FindBin qw/$Bin/;
use lib "$Bin/lib";

BEGIN {
    use_ok('DBIx::Squirrel', database_entities => [qw/db artist artists/]) || print "Bail out!\n";
    use_ok('T::Squirrel',    qw/:var diagdump/)                            || print "Bail out!\n";
}

diag("Testing DBIx::Squirrel $DBIx::Squirrel::VERSION, Perl $], $^X");

# Filter out artists whose ArtistId is outside the 128...131 range.
sub filter {($_->[0] < 128 or $_->[0] > 131) ? () : $_}

# Inject some additional (pending) results for the artist whose ArtistId is 128,
# else just return the artist's Name-field.
sub artist_name {($_->[0] == 128) ? ($_->[1], 'Envy of None', 'Alex Lifeson') : $_->[1]}

db(DBIx::Squirrel->connect(@TEST_DB_CONNECT_ARGS));
artist(db->results('SELECT * FROM artists WHERE ArtistId=? LIMIT 1'));
my $artist = artist->_private;

is_deeply($artist->{bind_values_initial}, [], 'bind_values_initial ok');
ok(!exists($artist->{bind_values}), 'bind_values ok');
is_deeply($artist->{transforms_initial}, [], 'transforms_initial ok');
ok(!exists($artist->{transforms}), 'transforms ok');

artist->iterate(128);
is_deeply($artist->{bind_values_initial}, [],                            'bind_values_initial ok');
is_deeply($artist->{bind_values},         [128],                         'bind_values ok');
is_deeply($artist->{transforms_initial},  [],                            'transforms_initial ok');
is_deeply($artist->{transforms},          $artist->{transforms_initial}, 'transforms ok');

artist->iterate(128)->next;
is_deeply($artist->{bind_values_initial}, [],    'bind_values_initial ok');
is_deeply($artist->{bind_values},         [128], 'bind_values ok');

artists(db->results('SELECT * FROM artists ORDER BY ArtistId' => \&filter => \&artist_name));
my $artists = artists->_private;

# This test will exercise buffer control, transformations, pending results injection and
# results filtering.
my $results  = artists->all;
my $expected = ['Rush', 'Envy of None', 'Alex Lifeson', 'Simply Red', 'Skank', 'Smashing Pumpkins'];
is_deeply($results, $expected, 'iteration, filtering, injection ok');

done_testing();
