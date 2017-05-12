use Test::More tests => 1;
use strict;

my @modules = qw(
	Brick::Composers
	);

foreach my $module ( @modules )
	{
	print "BAIL OUT!" unless use_ok( $module );
	}
