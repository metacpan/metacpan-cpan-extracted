use 5.010_001;
use strict;
use warnings;
use Carp qw/croak/;
use Test::Warn;
use FindBin qw/$Bin/;
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
    use_ok( 'DBIx::Squirrel', database_entities => [qw/db artist artists/] )
        or print "Bail out!\n";
    use_ok( 'T::Squirrel', qw/:var diagdump/ )
        or print "Bail out!\n";
    use_ok( 'DBIx::Squirrel::it', qw/result result_transform/ )
        or print "Bail out!\n";
}

diag("Testing DBIx::Squirrel $DBIx::Squirrel::VERSION, Perl $], $^X");

{
    note('DBIx::Squirrel::it::result_transform');

    my @tests = (
        { line => __LINE__, got => sub { result_transform() },            exp => [] },
        { line => __LINE__, got => sub { result_transform(4) },           exp => [4] },
        { line => __LINE__, got => sub { scalar( result_transform(4) ) }, exp => [1] },
        {
            line => __LINE__, got => sub { scalar( result_transform(4) ); $_ }, exp => [4],
        },
        {
            line => __LINE__,
            got  => sub {
                result_transform( [ sub { 2 * $_[0] } ], 2 );
            },
            exp => [4],
        },
        {
            line => __LINE__,
            got  => sub {
                result_transform( [ sub { 2 * $_[0] } => sub { 2 * $_[0] } ], 2 );
            },
            exp => [8],
        },
        {
            line => __LINE__,
            got  => sub {
                result_transform( [ sub { 4 * $_ } ], 4 );
            },
            exp => [16],
        },
        {
            line => __LINE__,
            got  => sub {
                result_transform( [ sub { 4 * $_ } => sub { 4 * $_ } ], 4 );
            },
            exp => [64],
        },
    );

    for my $t (@tests) {
        my $got = [ $t->{got}->() ];
        is_deeply( $got, $t->{exp}, sprintf( 'line %2d', $t->{line} ) );
    }
}

##############

{
    note('DBIx::Squirrel::it::rc');

    my @tests = (
        {
            line => __LINE__,
            got  => sub {
                result_transform( [ sub { 3 * result } ], 4 );
            },
            exp => [12],
        },
        {
            line => __LINE__,
            got  => sub {
                result_transform( [ sub { 3 * result } => sub { 3 * result } ], 4 );
            },
            exp => [36],
        },
    );

    for my $t (@tests) {
        my $got = [ $t->{got}->() ];
        is_deeply( $got, $t->{exp}, sprintf( 'line %2d', $t->{line} ) );
    }
}

# Filter out artists whose ArtistId is outside the 128...131 range.
sub filter { ( $_->[0] < 128 or $_->[0] > 131 ) ? () : $_ }

# Inject some additional (pending) results for the artist whose ArtistId is 128,
# else just return the artist's Name-field.
sub artist_name {
    ( $_->[0] == 128 ) ? ( $_->[1], 'Envy of None', 'Alex Lifeson' ) : $_->[1];
}

db( DBIx::Squirrel->connect(@TEST_DB_CONNECT_ARGS) );
artist( db->iterate('SELECT * FROM artists WHERE ArtistId=? LIMIT 1') );
my $artist = artist->_private_state;

is_deeply( $artist->{bind_values_initial}, [], 'bind_values_initial ok' );
ok( !exists( $artist->{bind_values} ), 'bind_values ok' );
is_deeply( $artist->{transforms_initial}, [], 'transforms_initial ok' );
ok( !exists( $artist->{transforms} ), 'transforms ok' );

artist->iterate(128);
is_deeply( $artist->{bind_values_initial}, [],    'bind_values_initial ok' );
is_deeply( $artist->{bind_values},         [128], 'bind_values ok' );
is_deeply( $artist->{transforms_initial},  [],    'transforms_initial ok' );
is_deeply(
    $artist->{transforms}, $artist->{transforms_initial},
    'transforms ok',
);

artist->iterate(128)->next;
is_deeply( $artist->{bind_values_initial}, [],    'bind_values_initial ok' );
is_deeply( $artist->{bind_values},         [128], 'bind_values ok' );

artists( db->iterate(
    'SELECT * FROM artists ORDER BY ArtistId' => \&filter => \&artist_name,
) );
my $artists = artists->_private_state;

# This test will exercise buffer control, transformations, pending results injection and
# results filtering.
my $results  = artists->all;
my $expected = [
    'Rush', 'Envy of None', 'Alex Lifeson', 'Simply Red', 'Skank',
    'Smashing Pumpkins',
];
is_deeply( $results, $expected, 'iteration, filtering, injection ok' );

done_testing();
