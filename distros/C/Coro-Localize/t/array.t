use Test::More tests => 8;
use Coro;
use Coro::Localize;
 
our @array = qw( main loop );

my @threads; 
push @threads, async {
    corolocal @array = qw( thread 1 );
    is( "1 - @array", "1 - thread 1", "array thread 1, test 1" );
    cede;
    is( "3 - @array", "3 - thread 1", "array thread 1, test 2" );
    cede;
    is( "5 - @array", "5 - thread 1", "array thread 1, test 3" );
};
 
push @threads, async {
    corolocal @array = qw( thread 2 );
    is( "2 - @array", "2 - thread 2", "array thread 2, test 1" );
    cede;
    is( "4 - @array", "4 - thread 2", "array thread 2, test 2" );
    cede;
    is( "6 - @array", "6 - thread 2", "array thread 2, test 3" );
};

is( "@array", "main loop", "array main, test 1" );
$_->join for @threads;
is( "@array", "main loop", "array main, test 2" );
