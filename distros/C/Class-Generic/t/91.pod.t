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

eval "use Test::Pod 1.00";
skip_all( "Test::Pod 1.00 required for testing POD" ) if( $@ );
all_pod_files_ok();

__END__

