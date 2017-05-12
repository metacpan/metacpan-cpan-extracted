#!perl -T

use Test::More tests => 224;
use Config::Param;

use strict;

# Test basic parameter regex parsing behaviour.

my $long_strict = $Config::Param::longex_strict;
my $long_lazy = $Config::Param::longex_lazy;
my $short_strict = $Config::Param::shortex_strict;
my $short_lazy = $Config::Param::shortex_lazy;

my @shorts_strict = qw(-x -x=bla -xyz -x.=u -x.=u -x+=3 -x-=2 -x*=4 -x/=0.4 -x+3 -x-2 -x*4 -x/0.4);
my @shorts_lazy   = (@shorts_strict, qw(x x=bla xyz x-=2 x*=4 x/=0.4 x+3 x-2 x*4 x/0.4));
my @longs_strict  = qw(--long --long=bla --long.=u --long+=4 --long-=2 --long*=23 --long/=4);
my @longs_lazy    = (@longs_strict, qw(-long=bla long=bla  long+=4 long-=2 long*=23 long/=4));

# first with -, then switch over to +

scanner();
for (@shorts_strict, @shorts_lazy, @longs_strict, @longs_lazy )
{
	s:-:+:g;
}
scanner();

sub scanner
{
	for(@shorts_strict)
	{
		# every member needs to qualify as short, but not as long
		ok(      $_ =~ $short_strict,  "strict short match on $_" );
		ok( (not $_ =~ $long_strict),  "strict long non-match on $_" );
	}

	for(@longs_strict)
	{
		# every member needs to qualify as long, but not as short
		ok( (not $_ =~ $short_strict),  "strict short non-match on $_" );
		ok(      $_ =~ $long_strict,    "strict long match on $_" );
	}

	for(@shorts_lazy)
	{
		# every member needs to qualify as short, but not as long
		ok(     $_ =~ $short_lazy,   "lazy short match on $_" );
		ok( (not $_ =~ $long_lazy),  "lazy long non-match on $_" );
	}

	for(@longs_lazy)
	{
		# every member needs to qualify as long, but not as short
		ok( (not $_ =~ $short_lazy), "lazy short non-match on $_" );
		ok(      $_ =~ $long_lazy,   "lazy long match on $_" );
	}
}
