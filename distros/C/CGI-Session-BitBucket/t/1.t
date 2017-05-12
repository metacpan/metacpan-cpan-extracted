use Test::More;
my @missing = grep { ! eval "require $_; 1" } qw/CGI::Session/;
plan skip_all => "requires @missing" if scalar @missing;
plan skip_all => "CGI::Session version must be 3.95 or earlier" if $CGI::Session::VERSION > 3.95;

	plan tests => 4;
	my $session = new CGI::Session("driver:BitBucket", undef, {Log=>1});	
	ok( $session );
	
	$session->param("hello", "world");
	ok( $session->param("hello") eq "world" );
	ok( $session->flush );
	eval {
		$session->delete;		
	};
	ok( !$@ );

