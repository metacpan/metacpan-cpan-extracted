# $Id$
$|++;

BEGIN {
	@classes = qw(Brick);
	
	push @classes, map { "Brick::$_" } qw(
		Bucket Composers Dates Filters
		Profile Result
		);
	}

use Test::More tests => 2 + scalar @classes;

foreach my $class ( @classes )
	{
	#print STDERR "Trying $class";
	#<STDIN>;
	BAIL_OUT( "$class did not compile\n" ) unless use_ok( $class );
	diag( "$class ---> " . $class->VERSION() . "\n" ) if $ENV{DEBUG};
	}

# API shims
ok( defined &Brick::create_pool );
ok( ! eval { Brick->create_pool } );