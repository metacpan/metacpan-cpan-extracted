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

    is
        Carp::Proxy::_display_code_or_string( undef ),
        '(undef)',
        "_display_code_or_string on 'undef' gives '(undef)'";

    like
        Carp::Proxy::_display_code_or_string( [] ),
        qr{ \A REF: [ ] ARRAY }x,
        "_display_code_or_string on '[]' gives 'ARRAY'";

    is
        Carp::Proxy::_display_code_or_string( 'string' ),
        'string',
        "_display_code_or_string on 'string' gives '(string)'";

    return;
}
