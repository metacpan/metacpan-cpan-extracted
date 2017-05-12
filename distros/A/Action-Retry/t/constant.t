use Action::Retry qw(retry);

use strict;
use warnings;

use Test::More;

{
    my $var = 0;
    my $action = Action::Retry->new(
        attempt_code => sub { $var++; die "plop" },
        strategy => { Constant => { sleep_time => 100 } },
    );
    $action->run();
    is($var, 11);
}

{
    my $var = 0;
    retry { $var++; die "plop" } strategy => { Constant => { sleep_time => 100 } };
    is($var, 11);    
}

done_testing;
