package TF_TestQuiet;

sub import {
	if( $ENV{HARNESS_ACTIVE} && ! ( $ENV{AUTHOR_TESTING} || $ENV{RELEASE_TESTING} ) ) {
		$ENV{TF_CPP_MIN_LOG_LEVEL} = 3;
	}
}

1;
