#!perl

package Foo;

use v5.10.1;

use Moo;

use Cache::FastMmap;
use Class::Method::Cache::FastMmap cache => { -as => 'memoize' };

has delay => (
    is      => 'ro',
    default => 1,
);

sub cache {
    state $cache = Cache::FastMmap->new();
    return $cache;
}

sub count {
    my ( $self, $count, $acc ) = @_;
    $acc //= 0;
    if ( $count <= 0 ) {
        return $acc;
    }
    else {
        sleep( $self->delay );
        return $self->count( $count - 1, $acc + $self->delay );
    }
}

memoize 'count' => (
    cache  => __PACKAGE__->cache,
    key_cb => sub { join( '-', $_[0]->[1], $_[0]->[2] // 0 ) },
);

package main;

use Test::Most;

my $obj = Foo->new;

foreach ( 1 .. 3 ) {
    my $start = time;
    is $obj->count($_) => $_, "first run ($_)";
    my $delay = time - $start;
    ok $_ <= $delay, "expected delay ($_ seconds)";

}

my @keys = $obj->cache->get_keys(0);
cmp_deeply \@keys,
    bag( map { "Foo::count::" . $_ } qw/ 0-1 0-2 0-3 1-0 1-1 1-2 2-0 2-1 3-0 / ),
    "get_keys";

foreach ( 1 .. 3 ) {
    my $start = time;
    is $obj->count($_) => $_, "cached run ($_)";
    my $delay = time - $start;
    ok $delay <= 1, "expected delay (<1 second)";
}

done_testing;
