# -*-cperl -*-
use warnings;
use strict;
use 5.010;

use English qw( -no_match_vars );
use Test::More;
use Test::Exception;

#----- t/files has a private version of Pod::Usage
use lib 't/files';

use Carp::Proxy;

main();
done_testing();

#-----

sub handler {
    my( $cp ) = @_;

    $cp->synopsis();
    return;
}

sub main {

    throws_ok{ fatal 'handler' }
        qr{
              \A
              ~+                      \r? \n
              \QFatal << handler >>\E \r? \n
              ~+                      \r? \n
              \Q  *** Synopsis ***\E  \r? \n
              \Q    Unable to create synopsis section\E .+?
              \Q    Oopsie\E
          }xs,
        'Synopsis gracefully handles failure of pod2usage';

    return;
}
