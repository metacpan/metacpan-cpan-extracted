use strict;
use Test::More;
use t::MyApp::Constant qw/ :fb_api_error /;

subtest 'export' => sub {
    is ERROR_OAUTH,       190;
    is ERROR_API_SESSION, 102;
    is ERROR_API_USER_TOO_MANY_CALLS, 17;
};

subtest 'not exported' => sub {
    eval "TITLE_MAX_LENGTH";
    if ($@) {
        like $@, qr/TITLE_MAX_LENGTH/
            and note $@;
    } else {
        fail "oops";
    }
};

done_testing;

