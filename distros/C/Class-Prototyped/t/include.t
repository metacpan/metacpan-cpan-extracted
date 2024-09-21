use strict;
$^W++;
use Class::Prototyped qw(:REFLECT);
use Data::Dumper;
use Test;
use IO::File;

BEGIN {
	$|++;
	plan tests => 18;
}

$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Sortkeys = 1;

package A;
sub Aa { 'Aaa' }

package main;

my $p  = Class::Prototyped->new();
my $pm = $p->reflect;

ok( !defined( $p->can('b') ) );
ok( !defined( $p->can('c') ) );
ok( !defined( $p->can('d') ) );
ok( !defined( $p->can('e') ) );
ok( !defined( $p->can('thisObject') ) );
ok( ! $p->isa( 'A' ) );
ok( scalar( () = $pm->slotNames ), 0 );

$pm->include( 't/include_xxx.pl', 'thisObject' );

ok( defined( $p->can('b') ) );
ok( defined( $p->can('c') ) );
ok( defined( $p->can('d') ) );
ok( defined( $p->can('e') ) );
ok( !defined( $p->can('thisObject') ) );
ok( $p->b, 'xxx.b' );
ok( $p->isa( 'A' ) );
ok( $p->Aa, 'Aaa' );
ok( scalar( ( ) = $pm->slotNames ) == 5 );
ok( !defined( eval { $p->c }  ) );
ok( $@ =~ /Undefined subroutine/ );
