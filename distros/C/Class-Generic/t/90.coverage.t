#!perl
BEGIN
{
    use lib './lib';
    use Test2::V0;
    # use Test::More;
	unless( $ENV{AUTHOR_TESTING} || $ENV{RELEASE_TESTING} )
	{
		skip_all( 'These tests are for author or release candidate testing' );
	}
};

eval "use Test::Pod::Coverage 1.04";
skip_all( "Test::Pod::Coverage 1.04 required for testing POD coverage" ) if( $@ );
my $trustme = { trustme => [qr/^(new|init|FREEZE|STORABLE_freeze|STORABLE_thaw|THAW|TO_JSON|TIEHASH|CLEAR|DELETE|EXISTS|FETCH|FIRSTKEY|NEXTKEY|SCALAR|STORE|PERL_VERSION)$/] };
all_pod_coverage_ok( $trustme );
