use Test::More;
eval "use Test::Pod::Coverage";

if( $@ )
	{
	plan skip_all => "Test::Pod::Coverage required for testing POD";
	}
else
	{
	plan tests => 1;

	pod_coverage_ok( "Data::Generate",
		{
		trustme => [ qr/^[A-Z_]+$/, qr/parse_line/ ]
		}
		);      
	}
