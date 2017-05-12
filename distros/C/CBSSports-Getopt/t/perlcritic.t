#!perl

if ( $ENV{AUTHOR_TESTS} ) {
    if ( !require Test::Perl::Critic ) {
        Test::More::plan( skip_all => "Test::Perl::Critic required for testing PBP compliance" );
    }
    Test::Perl::Critic::all_critic_ok();
}
else {
    require Test::More;
    Test::More::plan( tests => 1);
    SKIP: {
        Test::More::skip('Not running author tests - Environment variable AUTHOR_TESTS not defined', 1 );
    }
}
