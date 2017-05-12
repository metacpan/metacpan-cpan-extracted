use Action::Retry qw(retry);

use strict;
use warnings;

use Test::More;

{
    my $var = 0;
    my $action = Action::Retry->new(
        attempt_code => sub { my ($val) = @_; $var++; die "plop\n" if $var < 5; return $var + $val; },
        retry_if_code => sub { my ($error, $h) = @_;
                               chomp $error;
                               if ($var < 5) {
                                   is $error, "plop";
                                   return 1;
                               } else {
                                   ok ! $error;
                                   is $h->{attempt_result}, $var + $h->{attempt_parameters}[0];
                                   return 0;
                               }
                           },
        strategy => { Fibonacci => { initial_term_index => 0, multiplicator => 10 } },
    );
    my $result = $action->run(2);
    is($result, 7);
}

{
    my $var = 0;
    my $action = Action::Retry->new(
        attempt_code => sub { my ($val) = @_; $var++; die "plop" if $var < 5; return ( $var + $val, "plop"); },
        strategy => { Fibonacci => { initial_term_index => 0, multiplicator => 10 } },
    );
    my @result = $action->run(2);
    is_deeply(\@result, [ 7, "plop" ]);
}


done_testing;
