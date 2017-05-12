use strict;
use warnings;
use lib 't/lib';
use Test::More tests => 6;
use LoadTest;

BEGIN {
    $ENV{DBIC_TRACE} = 0;
}

my $raw_foo = LoadTest->source('Raw::Foo');

is_deeply( [ $raw_foo->columns ], [qw(id a)],
    'Columns for raw foo ok: id a' );

my $raw_bar = LoadTest->source('Raw::Bar');

is_deeply( [ $raw_bar->columns ], [qw(id b)],
    'Columns for raw bar ok: id b' );

ok( $raw_bar->has_relationship('parent'), 'parent rel exists' );

my $parent_info = $raw_bar->relationship_info('parent');

is( $parent_info->{source}, 'Raw::Foo', 'parent rel points to raw parent' );

my $foo = LoadTest->source('Foo');
my $bar = LoadTest->source('Bar');

is_deeply( [ $foo->columns ],
    [qw(id a)], 'Columns for mti foo are still the same: id a' );

is_deeply(
    [ $bar->columns ],
    [qw(id a words b)],
    'Columns for mti bar now contain those of foo and the mixin: id a words b'
);
