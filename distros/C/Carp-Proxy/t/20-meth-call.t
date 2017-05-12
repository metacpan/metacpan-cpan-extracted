# -*- cperl -*-
use warnings;
use strict;
use 5.010;

use English '-no_match_vars';
use Test::More;
use Test::Exception;

use Carp::Proxy;

main();
done_testing();

#----------------------------------------------------------------------

sub handler {
    my( $cp, $redirect, @args ) = @_;

    $cp->call( $redirect, @args );
    return;
}

sub aux {
    my( $cp, $stuff ) = @_;

    $cp->filled( $stuff );
    return;
}

sub main {

    #-----
    # Call should be able to invoke the builtin handlers.
    #-----
    throws_ok{ fatal 'handler', '*assertion_failure*', 'describe'; }
        qr{
             ^
             \QFatal << handler >>\E               \r? \n
             .+?
             \Q  *** Description ***\E             \r? \n
             .+?
             \Q    describe\E                      \r? \n
          }xms,
        'call() is able to invoke assertion_failure builtin';

    #-----
    # Call should be able to invoke sibling handlers
    #-----
    throws_ok{ fatal 'handler', 'aux', 'my description'; }
        qr{
             ^
             \QFatal << handler >>\E               \r? \n
             ~+                                    \r? \n
             \Q  *** Description ***\E             \r? \n
             \Q    my description\E                \r? \n
          }xms,
        'call() is able to invoke a sibling handler';

    return;
}
