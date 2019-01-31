use 5.20.0;

use Test::More;

use App::Dothe;

my $tasks = App::Dothe->new(
    target => '',
    vars => {
        foo => [ 1, 2 ] 
    }
);

is_deeply $tasks->vars->{foo}, [1,2];


done_testing;
