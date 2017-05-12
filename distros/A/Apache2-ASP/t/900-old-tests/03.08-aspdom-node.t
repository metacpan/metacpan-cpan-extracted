#!/usr/bin/env perl -w

use strict;
use warnings 'all';
use Test::More 'no_plan';
use Data::Dumper;
use Test::Memory::Cycle;

use_ok('Apache2::ASP::ASPDOM::Node');

my $node = Apache2::ASP::ASPDOM::Node->new();
ok( $node );

my $ref = sub {
  my ($s, $child) = @_;
#  warn "Adding $child to $s";
  ok(1, "Added a child");
};

# Make sure that we only add the same event handler once:
$node->addHandler( before_appendChild => $ref );
$node->addHandler( before_appendChild => $ref );
$node->addHandler( before_appendChild => $ref );
$node->addHandler( before_appendChild => $ref );
$node->addHandler( before_appendChild => $ref );
is( scalar(@{$node->{events}->{before_appendChild}}) => 1 );
$node->removeHandler( before_appendChild => $ref );
is( scalar(@{$node->{events}->{before_appendChild}}) => 0 );

$node->addHandler( before_appendChild => $ref );

my @ids = ( );

$node->appendChild( my $child1 = ref($node)->new( id => 'child1' ) );
for my $outer ( 1...10 )
{
  my $id = "child$outer";
  $child1->appendChild( my $sub = ref($child1)->new( id => $id ) );
  push @ids, $id;
  for my $inner ( 1...10 )
  {
    $sub->appendChild( my $baby = ref($sub)->new( id => "child$outer.sub$inner" ) );
    push @ids, $baby->{id};
  }# end for()
}# end for()
$node->appendChild( my $child2 = ref($node)->new( id => 'child2' ) );
$node->removeHandler( before_appendChild => $ref );

foreach( @ids )
{
  my $by_id = $node->getElementById( $_ );
  ok( $by_id, "\$node->getElementById('$_')" );
}# end foreach()

is( scalar($node->childNodes) => 2 );

$node->removeChild( $child1 );

is( scalar($node->childNodes) => 1 );

memory_cycle_ok( $node );


