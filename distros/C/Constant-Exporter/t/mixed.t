use strict;
use Test::More;
use t::MyApp::Constant qw/ TITLE_MAX_LENGTH :fb_api_error /;

subtest 'export' => sub {
    is TITLE_MAX_LENGTH,  128;
    is ERROR_OAUTH,       190;
    is ERROR_API_SESSION, 102;
    is ERROR_API_USER_TOO_MANY_CALLS, 17;
};

subtest 'not exported' => sub {
    eval "ERROR_PAYMENTS_ASSOCIATION_FAILURE";
    if ($@) {
        like $@, qr/ERROR_PAYMENTS_ASSOCIATION_FAILURE/
            and note $@;
    } else {
        fail "oops";
    }
};

done_testing;


