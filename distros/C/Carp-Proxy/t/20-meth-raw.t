# -*- cperl -*-
use warnings;
use strict;
use 5.010;

use English qw( -no_match_vars );

use Test::More;
use Test::Exception;

use Carp::Proxy fatal => { context => 'none' };

main();
done_testing();

#-----

sub handler {
    my( $cp ) = @_;

    $cp->raw(<<'EOF');
Title
Body
EOF
    return;
}

sub main {

    throws_ok{ fatal 'handler' }
        qr{
              \A
              ~+                       \r? \n
              \QFatal << handler >>\E  \r? \n
              ~+                       \r? \n
              Title \r? \n
              Body \r? \n
              \z
          }x,
        'Raw section rendered exactly as specified';

    return;
}
