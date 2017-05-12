use strict;
$^W++;
use Class::Prototyped qw(:REFLECT);
use Data::Dumper;
use Test;

BEGIN {
	$|++;
	plan tests => 5;
}

$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Sortkeys = 1;

package A;
sub a {'A.a'}
sub aa {'A.aa'}

package B;
@B::ISA = 'A';
sub aa {'B.aa'}
sub b {'B.b'}

package C;
@C::ISA = qw(B A);
sub aa {'C.aa'}
sub c {'C.c'}

package D;
@D::ISA = qw(C C B B A A);
sub aa {'D.aa'}
sub d {'D.d'}

package main;

sub sorted { join('|', sort(@_)) }

my $p = Class::Prototyped->new();
my $pm = $p->reflect;
my $am = Class::Prototyped::reflect('A');
my $bm = Class::Prototyped::reflect('B');
my $cm = Class::Prototyped::reflect('C');
my $dm = Class::Prototyped::reflect('D');

my @a;
ok( sorted( @a = $pm->slotNames), '' );
ok( sorted( @a = $am->slotNames), 'a|aa' );
ok( sorted( @a = $bm->slotNames), 'A*|aa|b' );
ok( sorted( @a = $cm->slotNames), 'A*|B*|aa|c' );
ok( sorted( @a = $dm->slotNames), 'A*|A1*|B*|B1*|C*|C1*|aa|d' );

# vim: ft=perl
