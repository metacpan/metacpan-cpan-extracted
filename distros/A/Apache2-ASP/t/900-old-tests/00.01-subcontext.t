#!/usr/bin/perl -w

use strict;
use warnings 'all';
use Test::More 'no_plan';
use Apache2::ASP::API;

my $api; BEGIN { $api = Apache2::ASP::API->new }

for(1..5)
{
  my $res = $api->ua->get("/handlers/simple");
  is( $res->content => "HELLO WORLD", '/handlers/simple');
}

# Normal page:
for( 1..5 )
{
  my $res = $api->ua->get("/subcontext/normal.asp");
  is( $res->content => "Normal Page\n", 'normal' );
}


# Include 1 level deep:
for(1..5)
{
  my $res = $api->ua->get("/subcontext/include-1-level-deep.asp");
  is( $res->content => "Before\nInclude1\n\nInclude2\n\nAfter\n", 'include-1' );
}


# Include 2 levels deep:
for( 1..5 )
{
  my $res = $api->ua->get("/subcontext/include-2-levels-deep.asp");
#warn "[[" . $res->content . "]]";
  is( $res->content => "Before\n2.Include1\n2.Include2\n\n\nAfter\n", 'include-2' );
}


# Include 1 level deep:
for(1..5)
{
  my $res = $api->ua->get("/subcontext/include-1-level-deep.asp");
  is( $res->content => "Before\nInclude1\n\nInclude2\n\nAfter\n", 'include-1' );
}


# TrapInclude:
for(1..2)
{
  my $res = $api->ua->get("/subcontext/trapinclude.asp");
  is( $res->content => "Before\nTrapInclude\n\nAfter\n", 'trapinclude' );
}

