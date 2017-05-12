#!/usr/local/bin/perl
use strict;
use warnings;

use Test::More tests => 43;
use Array::Each;

my $obj = Array::Each->new();  # defaults only

# Testing attribute defaults:
# _each set iterator rewind bound undef stop group count user

is( $obj->_get_each_name, '&Array::Each::each_default', "default _each" );
is( $obj->get_set(), 1, "default set" );
is( $obj->get_iterator, 0, "default iterator" );
is( $obj->get_rewind(), 0, "default rewind" );
is( $obj->get_bound(), 1, "default bound" );
ok( !defined $obj->get_undef, "default undef" );
ok( !defined $obj->get_stop(), "default stop" );
ok( !defined $obj->get_group(), "default group" );
ok( !defined $obj->get_count(), "default count" );
ok( !defined $obj->get_user(), "default user" );


# Testing initializations:
# _each set iterator rewind bound undef stop group count user

$obj = Array::Each->new(
    set      => [['a'..'c'], [1..3], ['x'..'z']],
    iterator => 1,
    rewind   => 1,
    bound    => 0,
    undef    => '_',
    stop     => 1,
    group    => 1,
    count    => 1,
    user     => 1,
    _each    => \&Array::Each::each_default,
    );

is( $obj->_get_each_name, '&Array::Each::each_default', "init'd _each" );
$obj->_set_each();
is( $obj->_get_each_name, '&Array::Each::each_complete', "_each restored" );

{
my @s = $obj->get_set();
is( @s, 3, "init'ed set(1)" );
is( "@{$s[0]} @{$s[1]} @{$s[2]}", 'a b c 1 2 3 x y z' ,
    "init'ed set(2)" );
}

is( $obj->get_iterator(), 1, "init'ed iterator" );
is( $obj->get_rewind(), 1, "init'ed rewind" );
is( $obj->get_bound(), 0, "init'ed bound" );
is( $obj->get_undef(), '_', "init'ed undef" );
is( $obj->get_stop(), 1, "init'ed stop" );
is( $obj->get_group(), 1, "init'ed group" );
is( $obj->get_count(), 1, "init'ed count" );
is( $obj->get_user(), 1, "init'ed user" );


# Testing get/set methods:
# _each set iterator rewind bound undef stop group count user

{
my $was = $obj->_get_each_ref;
my $e = $obj->_set_each( \&Array::Each::each_unbound );
is( $e, \&Array::Each::each_unbound, "_set_each return" );
is( $obj->_get_each_ref, \&Array::Each::each_unbound, "_get_each_ref return" );
is( $obj->_get_each_name, '&Array::Each::each_unbound', "_get_each_name return" );
is( $obj->_set_each, $was, "_each restored" );
}

{
my $s = $obj->set_set( ['a'..'e'], [1..5] );
is( $s, 2, "set_set return" );
my @s = $obj->get_set();
is( @s, 2, "get_set return(1)" );
is( "@{$s[0]} @{$s[1]}", 'a b c d e 1 2 3 4 5',
    "get_set return(2)" );
}

{
my $i = $obj->set_iterator( 10 );
is( $i, 10, "set_iterator return" );
is( $obj->get_iterator, 10, "get_iterator return" );
}

{
my $r = $obj->set_rewind( 1 );
is( $r, 1, "set_rewind return" );
is( $obj->get_rewind, 1, "get_rewind return" );
}

{
my $b = $obj->set_bound( 1 );
is( $b, 1, "set_bound return" );
is( $obj->get_bound, 1, "get_bound return" );
}

{
my $u = $obj->set_undef( 0 );
is( $u, 0, "set_undef return" );
is( $obj->get_undef(), 0, "get_undef return" );
}

{
my $s = $obj->set_stop( 20 );
is( $s, 20, "set_stop return" );
is( $obj->get_stop(), 20, "get_stop return" );
}

{
my $g = $obj->set_group( 2 );
is( $g, 2, "set_group return" );
is( $obj->get_group(), 2, "get_group return" );
}

{
my $g = $obj->set_count( 0 );
is( $g, 0, "set_count return" );
is( $obj->get_count(), 0, "get_count return" );
}

# no set_user() defined

__END__
