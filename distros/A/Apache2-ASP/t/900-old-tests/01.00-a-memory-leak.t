#!/usr/bin/env perl -w

use strict;
use warnings 'all';
use base 'Apache2::ASP::Test::Base';
use Test::More 'no_plan';
use Test::Memory::Cycle;

ok( 1 );

my $s = __PACKAGE__->SUPER::new();

$s->ua->get("/hello-world.asp");
$s->ua->get("/index.asp");

__END__

for( 1...100 )
{
  $s->ua->get("/hello-world.asp");
  
  memory_cycle_ok( $s->ua->context );
}# end for()


