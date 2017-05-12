#!/usr/local/bin/perl
use strict;
use warnings;

use Test::More tests => 14;
use Array::Each;

# Testing method copy()

my $obj = Array::Each->new(
    set      => [['a'..'c'], [1..3], ['x'..'z']],
    iterator => 1,
    rewind   => 1,
    bound    => 0,
    undef    => '_',
    stop     => 1,
    group    => 1,
    count    => 1,
    );

my $cpy = $obj->copy();

my @s = $cpy->get_set();
is( @s, 3, "copy set" );
is( "@{$s[0]} @{$s[1]} @{$s[2]}", 'a b c 1 2 3 x y z' ,
    "copy set" );

is( $cpy->get_iterator(), 1, "copy iterator" );
is( $cpy->get_rewind(), 1, "copy rewind" );
is( $cpy->get_bound(), 0, "copy bound" );
is( $cpy->get_undef(), '_', "copy undef" );
is( $cpy->get_stop(), 1, "copy stop" );
is( $cpy->get_group(), 1, "copy group" );
is( $cpy->get_count(), 1, "copy count" );

# Testing utility methods

{
my $r = $cpy->rewind( 10 );
is( $r, 10, "rewind return" );
is( $cpy->get_iterator(), 10, "get_iterator after rewind" );
}

{
$cpy->rewind();  # i.e., 1
my $i = $cpy->incr_iterator();
is( $i, 1, "incr_iterator return" );
is( $cpy->get_iterator, 2, "get_iterator after incr_iterator" );
}

$cpy->set_group( 4 );
$cpy->rewind();  # i.e., 1
$cpy->incr_iterator();
is( $cpy->get_iterator(), 5, "incr_iterator with group" );

__END__
