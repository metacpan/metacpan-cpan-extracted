#!perl

package Foo;

use Moo;

use Class::Method::Cache::FastMmap;

has delay => (
    is      => 'ro',
    default => 1,
);

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

cache 'count' => ( key_cb => sub { join( $;, $_[0]->[1], $_[0]->[2] // 0 ) }, );

package main;

use Test::Most;

my $obj = Foo->new;

foreach ( 1 .. 3 ) {
    my $start = time;
    is $obj->count($_) => $_, "first run ($_)";
    my $delay = time - $start;
    ok $_ <= $delay, "expected delay ($_ seconds)";

}

foreach ( 1 .. 3 ) {
    my $start = time;
    is $obj->count($_) => $_, "cached run ($_)";
    my $delay = time - $start;
    ok $delay <= 1, "expected delay (<1 second)";
}

done_testing;
