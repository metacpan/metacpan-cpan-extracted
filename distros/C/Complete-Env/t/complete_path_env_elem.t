#!perl

use 5.010;
use strict;
use warnings;

use Test::More 0.98;

use Complete::Env qw(complete_path_env_elem);

local $Complete::Common::OPT_FUZZY = 0;

{
    local $ENV{PATH} = 'foo:bar:baz';
    test_complete(
        word      => 'ba',
        result    => [qw(bar baz)],
    );
}

DONE_TESTING:
done_testing();

sub test_complete {
    my (%args) = @_;

    my $name = $args{name} // $args{word};
    my $res = complete_path_env_elem(word=>$args{word});
    is_deeply($res, $args{result}, "$name (result)")
        or diag explain($res);
}
