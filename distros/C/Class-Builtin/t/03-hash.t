#!perl -T
use strict;
use warnings;
use Class::Builtin;
use Test::More qw/no_plan/; #tests => 1;

my $o = OO( { key => 'value' } );
is( ref $o,          'Class::Builtin::Hash', ref $o );
is( $o->{key}, 'value');
ok( $o->exists('key') );
is( $o->keys->[0],   'key',         'keys' );
is( $o->values->[0], 'value',       'values' );
is( $o->length,      1 );
$o->each(
    sub {
        is $_[0], 'key';
        is $_[1], 'value';
    }
);
