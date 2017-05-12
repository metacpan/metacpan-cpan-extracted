use Test::More tests => 8;
use Coro;
use Coro::Localize;
 
our %hash = qw( main loop );

my @threads; 
push @threads, async {
    corolocal %hash = qw( thread 1 );
    is( "1 - @{[ map {qq{$_ => $hash{$_}}} keys %hash ]}", "1 - thread => 1", "hash thread 1, test 1" );
    cede;
    is( "3 - @{[ map {qq{$_ => $hash{$_}}} keys %hash ]}", "3 - thread => 1", "hash thread 1, test 2" );
    cede;
    is( "5 - @{[ map {qq{$_ => $hash{$_}}} keys %hash ]}", "5 - thread => 1", "hash thread 1, test 3" );
};
 
push @threads, async {
    corolocal %hash = qw( thread 2 );
    is( "2 - @{[ map {qq{$_ => $hash{$_}}} keys %hash ]}", "2 - thread => 2", "hash thread 2, test 1" );
    cede;
    is( "4 - @{[ map {qq{$_ => $hash{$_}}} keys %hash ]}", "4 - thread => 2", "hash thread 2, test 2" );
    cede;
    is( "6 - @{[ map {qq{$_ => $hash{$_}}} keys %hash ]}", "6 - thread => 2", "hash thread 2, test 3" );
};

is( "@{[ map {qq{$_ => $hash{$_}}} keys %hash ]}", "main => loop", "hash main, test 1" );
$_->join for @threads;
is( "@{[ map {qq{$_ => $hash{$_}}} keys %hash ]}", "main => loop", "hash main, test 2" );
