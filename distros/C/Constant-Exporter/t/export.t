use strict;
use Test::More;
use t::MyApp::Constant;

subtest 'export' => sub {
    is FB_CLIENT_ID, 12345;
    is USER_STATUS_FB_ASSOCIATED,     1;
    is USER_STATUS_FB_NOT_ASSOCIATED, 0;
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
