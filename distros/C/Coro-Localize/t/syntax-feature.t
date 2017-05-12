use Test::More ();
BEGIN {
    eval q{
        require syntax;
    };
    if ( $@ ) {
        Test::More->import( skip_all => "Syntax::Feature not installed\n$@" );
    }
    else {
        Test::More->import( tests => 8 );
    }
}
use Coro;
use syntax qw( corolocal );
 
our $scalar = "main loop";

my @threads; 
push @threads, async {
    corolocal $scalar = "thread 1";
    is( "1 - $scalar", "1 - thread 1", "scalar thread 1, test 1" );
    cede;
    is( "3 - $scalar", "3 - thread 1", "scalar thread 1, test 2" );
    cede;
    is( "5 - $scalar", "5 - thread 1", "scalar thread 1, test 3" );
};
 
push @threads, async {
    corolocal $scalar = "thread 2";
    is( "2 - $scalar", "2 - thread 2", "scalar thread 2, test 1" );
    cede;
    is( "4 - $scalar", "4 - thread 2", "scalar thread 2, test 2" );
    cede;
    is( "6 - $scalar", "6 - thread 2", "scalar thread 2, test 3" );
};

is( $scalar, "main loop", "scalar main, test 1" );
$_->join for @threads;
is( $scalar, "main loop", "scalar main, test 2" );
