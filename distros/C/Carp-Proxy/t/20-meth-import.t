# -*- cperl -*-
use warnings;
use strict;
use 5.010;

use English '-no_match_vars';
use Test::More;
use Test::Exception;

use Carp::Proxy ();

main();
done_testing();

#----------------------------------------------------------------------

sub main {

    lives_ok{ Carp::Proxy->import() }
        'No-arg import returns normally';

    ok
        __PACKAGE__->can( 'fatal' ),
        'No-arg import produces fatal()';

    lives_ok{ Carp::Proxy->import( 'implicit' ) }
        'One-arg import returns normally';

    ok
        __PACKAGE__->can( 'implicit' ),
        'One-arg import produces named proxy';

    throws_ok{ Carp::Proxy->import( proxy1 => {}, 'proxy2' )}
        qr{
              \QOops << unmatched proxy arglist >>\E
          }x,
        'import with odd-numbered arguments throws';

    return;
}
