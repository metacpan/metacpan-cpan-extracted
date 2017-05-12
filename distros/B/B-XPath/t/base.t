#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 31;

use_ok( 'B::XPath' );

sub some_sub
{
	my $x        = shift;
	return $x * 2;
}

my $node = B::XPath->fetch_root( \&some_sub );

isa_ok( $node, 'B::XPath::UNOP' );
my @kids = $node->get_children(); 
is( @kids, 1, '... with one child' );
is( $kids[0]->get_name(), 'lineseq', '... a lineseq op' );
@kids = $kids[0]->get_children();
is( @kids, 4, 'lineseq should have four children' );
is( $kids[0]->get_name(), 'nextstate', '... a COP' );
is( $kids[1]->get_name(), 'sassign',   '... a scalar assignment' );
is( $kids[2]->get_name(), 'nextstate', '... another COP' );
is( $kids[3]->get_name(), 'return',    '... and a return' );

my $ns = $kids[1]->get_nextstate();
is( $ns->line(), $kids[0]->line(),
	'get_nextstate() for assignment should find closest previous COP' );

$ns    = $kids[3]->get_nextstate();
is( $ns->line(), $kids[2]->line(),
	'get_nextstate() for return should find closest previous COP' );

my $sassign = $kids[1];
my @skids   = $sassign->get_children();
is( @skids, 2, 'sassign should have two children' );
is( $skids[0]->get_name(), 'shift', '... one a shift' );
is( $skids[1]->get_name(), 'padsv', '... and the other a scalar pad op' );

my @shkids = $skids[0]->get_children();
is( @shkids, 1, 'shift should have one child' );
is( $shkids[0]->get_name(), 'rv2av', '... an array reference op' );

my @rvkids = $shkids[0]->get_children();
is( @rvkids, 1, '... itself having one child' );
is( $rvkids[0]->get_name(), 'gv', '... a GV dereference' );
is( $rvkids[0]->NAME(), '_',  '... working on @_' );
is( $rvkids[0]->get_nextstate->line(), $kids[0]->line(),
	'get_nextstate() should find closest previous COP' );

my $ret   = $kids[3];
my @rkids = $ret->get_children();
is( @rkids, 2, 'return should have two children' );
is( $rkids[0]->get_name(), 'pushmark', '... a stack manipulator' );
is( $rkids[1]->get_name(), 'multiply', '... and a multiplication op' );

my @mkids = $rkids[1]->get_children();
is( @mkids, 2, 'multiply should have two children' );
is( $mkids[0]->get_name(), 'padsv', '... a pad scalar op' );
is( $mkids[1]->get_name(), 'const', '... and a const op' );
is( $mkids[1]->IV(),             2, '... with a value of 2' );
is( $mkids[1]->get_line(), $kids[2]->line(),
	'get_nextstate() should find closest previous COP' );

my @ckids = $mkids[1]->get_children();
is( @ckids, 0, 'const should have no children' );

my $parent = B::XPath->fetch_main_root();
isa_ok( $parent, 'B::XPath::Node' );
is( $parent->parent(), undef, 'main root should have no parent' );
