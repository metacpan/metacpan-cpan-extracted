use strict;
$^W++;
use Class::Prototyped qw(:REFLECT);
use Data::Dumper;
use Test;

BEGIN {
	$|++;
	plan tests => 12;
}

$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Sortkeys = 1;

package A;
sub a {'A.a'}

package main;

my $p = Class::Prototyped->new();
my $pm = $p->reflect;

my $a = A->reflect;

my @slotNames = $a->slotNames;
ok( @slotNames, 1 );
ok( $slotNames[0], 'a' );

my @slots = $a->getSlots;
ok( scalar @slots, 2 );
ok( $slots[0]->[0], 'a' );
ok( $slots[0]->[1], 'METHOD');
ok( $a->getSlot('a') == UNIVERSAL::can( 'A', 'a' ) );

$a->addSlots( 'bb' => sub {'A.bb'} );

@slotNames = $a->slotNames;
ok( @slotNames, 2 );

my %slots = $a->getSlots(undef, 'simple');
ok( scalar keys %slots, 2 );
ok( defined( $slots{bb} ) );
ok( $a->getSlot('bb') == A->can('bb') );

ok( ref( $a->object ), 'A' );
ok( defined( UNIVERSAL::can( 'A', 'bb' ) ) );

# vim: ft=perl
