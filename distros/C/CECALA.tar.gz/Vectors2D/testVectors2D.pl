#!/usr/bin/perl
use strict;
use lib ('.');
use Vectors2D;

my $u = new Vector2D ( 1, 3 );
my $v = new Vector2D ( 10, 30 );

#print "$v\n";
my $X = $v->getx();
my $Y = $v->gety();
print "[$X,$Y]\n";
my @XY = $v->getxy();
print "XY = @XY\n";

my $uv = $u->plus ( $v ); @XY = $uv->getxy(); print "XY = @XY\n";
my $UV = $u + $v; @XY = $UV->getxy(); print "UV XY = @XY\n";
my $vu = $v->minus( $v ); @XY = $vu->getxy(); print "XY = @XY\n";
my $VU = $v - $v; @XY = $VU->getxy(); print "VU XY = @XY\n";
my $vc = $v->mult (  2 ); @XY = $vc->getxy(); print "XY = @XY\n";
my $VC = $v * 2; @XY = $vc->getxy(); print "VC XY = @XY\n";

$u->incr( $v );
$X = $u->getx(); $Y = $u->gety(); print "[$X,$Y]\n";
$u->decr( $v );
$X = $u->getx(); $Y = $u->gety(); print "[$X,$Y]\n";
$u->scale( 5 );
$X = $u->getx(); $Y = $u->gety(); print "[$X,$Y]\n";
