#!perl

use 5.010;
use strict;
use warnings;

use Test::More 0.98;

use Complete::Env qw(complete_env);

local $Complete::Common::OPT_FUZZY = 0;

{
    local %ENV = (APPLE=>1, AWAY=>2, DOCTOR=>3, AN=>4);
    test_complete(
        word      => 'A',
        result    => [qw(AN APPLE AWAY)],
    );
}

DONE_TESTING:
done_testing();

sub test_complete {
    my (%args) = @_;

    my $name = $args{name} // $args{word};
    my $res = complete_env(word=>$args{word});
    is_deeply($res, $args{result}, "$name (result)")
        or diag explain($res);
}
