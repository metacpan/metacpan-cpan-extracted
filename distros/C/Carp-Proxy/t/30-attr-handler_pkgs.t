# -*- cperl -*-
use warnings;
use strict;
use 5.010;

use English '-no_match_vars';
use Test::More;
use Test::Exception;

BEGIN {
    use_ok( 'Carp::Proxy',
            fatal    => {                          },
            fatal_hp => { handler_pkgs => ['other']},
          );
}

main();
done_testing();

#----------------------------------------------------------------------

#-----
# This handler resides in the same package (main) where use() was run,
# so it should be found by the HANDLER SEARCH algorithm.
#-----
sub handler {
    my( $cp, $setting ) = @_;

    $cp->handler_pkgs( $setting )
        if @_ > 1;

    $cp->filled('Diagnostic message here');
    return;
}

#-----
# Here we have another handler, with the same name as the previous handler,
# but in a different package.  This handler should take precedence when
# invoked by 'fatal_hp'
#-----
sub other::handler {
    my( $cp ) = @_;

    $cp->filled('Hello from other');
    return;
}

#-----
# Here we have a handler name that is only found in main::.  'fatal_hp'
# should find this one after being unable to find other::handler2, thus
# verifying the package fallback behavior in HANDLER SEARCH.
#-----
sub handler2 {
    my( $cp ) = @_;

    $cp->filled('Hello from handler2');
    return;
}

sub main {

    throws_ok{ fatal 'handler' }
        qr{ \QDiagnostic message here\E }x,
        'Handler search finds default (base) handler';

    throws_ok{ fatal_hp 'handler' }
        qr{ \QHello from other\E }x,
        'Precedence observed in handler_pkgs';

    throws_ok{ fatal_hp 'handler2' }
        qr{ \QHello from handler2\E }x,
        'Traversal observed in handler_pkgs';

    return;
}
