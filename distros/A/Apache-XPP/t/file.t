use Test::More tests => 7;

BEGIN { use_ok( 'Apache::XPP' ); }

{
	my $xpml	= Apache::XPP->new( { filename => 't/test_print.xpml' } );
	isa_ok( $xpml, 'Apache::XPP' );
	can_ok( $xpml, 'returnrun' );
	is( $xpml->returnrun, 'Hello World', "Print tag" );
}

{
	my $xpml	= Apache::XPP->new( { filename => 't/test_run.xpml' } );
	isa_ok( $xpml, 'Apache::XPP' );
	can_ok( $xpml, 'returnrun' );
	is( $xpml->returnrun, 'Hello World', "Run tag" );
}

