# -*- cperl -*-
use warnings;
use strict;
use 5.010;

use English qw( -no_match_vars );
use Test::More;
use Test::Exception;

use Carp::Proxy;

main();
done_testing();

#-----

sub handler {
    my( $cp ) = @_;

    $cp->tags( { a => 1, b => 2 });

    return;
}

sub main {

    eval{ fatal 'handler' };

    my $ex = $EVAL_ERROR;

    ok
        defined( $ex ),
        'Handler threw an exception';

    isa_ok
        $ex,
        'Carp::Proxy',
        'The exception was a Carp::Proxy object';

    is_deeply
        $ex->tags,
        { a => 1, b => 2 },
        'The tags attribute was propagated up from the handler';

    return;
}
