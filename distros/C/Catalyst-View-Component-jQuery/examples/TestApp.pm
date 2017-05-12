package TestApp;
use strict;
use warnings;

use Catalyst qw(
    ConfigLoader
    Static::Simple
);

my $jquery_version = '1.3.2';
my $jquery_ui_version = '1.7.1';

__PACKAGE__->config(
    default_view => 'TT',
    'View::TT' => {
        'JavaScript::Framework::jQuery' => {
            library => {
                src => [
                "http://ajax.googleapis.com/ajax/libs/jquery/${jquery_version}/jquery.min.js",
                "http://ajax.googleapis.com/ajax/libs/jqueryui/${jquery_ui_version}/jquery-ui.min.js",
                ],
                css => [
                {
                    href => '/static/css/theme/jquery-ui.custom.css',
                    media => 'all',
                },
                ],
            },
            plugins => [
                {
                    name => 'Superfish',
                    library => {
                        src => [
                        '/static/js/hoverIntent.js',
                        '/static/js/superfish.js',
                        '/static/js/supersubs.js',
                        ],
                        css => [
                        { href => '/static/css/superfish.css', media => 'all' },
                        { href => '/static/css/superfish-vertical.css', media => 'all' },
                        { href => '/static/css/superfish-navbar.css', media => 'all' },
                        { href => '/static/site/css/superfish.css', media => 'all' },
                        { href => '/static/site/css/superfish-skin.css', media => 'all' },
                        ],
                    },
                },
            ],
        },
    },
);

__PACKAGE__->setup;

1;
