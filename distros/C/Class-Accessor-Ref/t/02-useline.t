#!perl -w

use Test::More tests => 5;

package Fish;
use Class::Accessor::Ref qw(moose elk);

package main;

my $obj = Fish->new({ moose => 'bullwinkle', elk => 'harry' });
isa_ok($obj, "Fish");
can_ok($obj, "moose");
can_ok($obj, "_ref_moose");
is($obj->elk, "harry");
${ $obj->_ref_elk } =~ s/h/H/;
is($obj->elk, "Harry");

