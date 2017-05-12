use Test::More tests => 7;

BEGIN { use_ok( 'Apache::XPP' ); }

{
	my $xpml	= Apache::XPP->new( { source => 'Hello <?= "World" ?>' } );
	isa_ok( $xpml, 'Apache::XPP' );
	can_ok( $xpml, 'returnrun' );
	is( $xpml->returnrun, 'Hello World', "Print tag" );
}

{
	my $xpml	= Apache::XPP->new( { source => 'Hello <?xpp print "World" ?>' } );
	isa_ok( $xpml, 'Apache::XPP' );
	can_ok( $xpml, 'returnrun' );
	is( $xpml->returnrun, 'Hello World', "Run tag" );
}

