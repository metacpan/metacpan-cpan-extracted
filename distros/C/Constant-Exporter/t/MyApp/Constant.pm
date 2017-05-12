package t::MyApp::Constant;
use strict;
use warnings;

use Constant::Exporter (
    EXPORT => {
        FB_CLIENT_ID => 12345,
    },
    EXPORT_OK => {
        TITLE_MAX_LENGTH => 128,
    },
    EXPORT_TAGS => {
        user_status => {
            USER_STATUS_FB_ASSOCIATED     => 1,
            USER_STATUS_FB_NOT_ASSOCIATED => 0,
        },
    },
    EXPORT_OK_TAGS => {
        fb_api_error => {
            ERROR_OAUTH       => 190,
            ERROR_API_SESSION => 102,
            ERROR_API_USER_TOO_MANY_CALLS => 17,
        },
        fb_payment_error => {
            ERROR_PAYMENTS_ASSOCIATION_FAILURE   => 1176,
            ERROR_PAYMENTS_INSIDE_IOS_APP        => 1177,
            ERROR_PAYMENTS_NOT_ENABLED_ON_MOBILE => 1178,
        },
    },
);

1;
__END__
