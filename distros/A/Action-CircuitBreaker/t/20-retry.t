use Action::CircuitBreaker;

use strict;
use warnings;

use Test::More;

use Try::Tiny;
use Action::Retry;

{
    my $died = 0;
    my $action = Action::CircuitBreaker->new(max_retries_number => 9);
    try {
      my $foo = Action::Retry->new(
          attempt_code => sub { $action->run(sub { die "plop"; }) }, # ie. the database failed
          on_failure_code => sub { my ($error, $h) = @_; die $error; }, # by default Action::Retry would return undef
      )->run();
    } catch {
        $died = 1;
    };

    is($died, 1);
}

done_testing;
