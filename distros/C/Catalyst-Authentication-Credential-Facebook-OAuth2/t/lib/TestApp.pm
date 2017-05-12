package TestApp;

use Moose;

extends 'Catalyst';

__PACKAGE__->config(
    'Plugin::Authentication' => {
        default => {
            credential => {
                class              => 'Facebook::OAuth2',
                application_id     => $ENV{FACEBOOK_APPLICATION_ID},
                application_secret => $ENV{FACEBOOK_APPLICATION_SECRET},
            },
            store => {
                class => 'Null',
            },
        },
    },
);

__PACKAGE__->setup(qw(
    Authentication
));

1;
