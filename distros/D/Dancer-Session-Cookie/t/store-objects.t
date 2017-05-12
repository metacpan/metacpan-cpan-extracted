use strict;
use warnings;

use Test::More tests => 1;

{
    use Dancer ':tests';

    set session_cookie_key => 'chocolate chips';
    set session            => 'Cookie';

    get '/' => sub {
        session 'foo' => bless {}, 'SomeClass';

        return 'ok';
    }

}

use Dancer::Test;

response_status_is '/' => 200, "session handles objects";
