use Test::More;

if ( not $ENV{AUTHOR_TESTING} ) {
    my $msg = 'Author test. Set $ENV{AUTHOR_TESTING} to a true value to run.';
    plan( skip_all => $msg );
}
else {

	eval {
		require Test::Kwalitee;
		Test::Kwalitee->import( tests => [qw( -has_meta_yml)] );
	};

	plan( skip_all => 'Test::Kwalitee not installed; skipping' ) if $@;

}
