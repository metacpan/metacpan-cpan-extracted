package TestApp;
use strict;
use warnings;

use Catalyst qw(
    ConfigLoader
);
#-Debug

__PACKAGE__->config(
    default_view => 'TT',
    'View::TT' => {
        'JavaScript::Framework::jQuery' => {
            library => {
                src => [ 'jquery.js' ],
                css => [
                    { href => 'jquery-ui.css', media => 'all'},
                ],
            },
            plugins => [
                {
                    name => 'Superfish', 
                    library => {
                        src => [ 'superfish.js' ],
                        css => [
                            { href => 'superfish.css', media => 'all' },
                        ],
                    },
                },
                {
                    name => 'mcDropdown', 
                    library => {
                        src => [ 'menu.js' ],
                        css => [
                            { href => 'menu.css', media => 'all' },
                        ],
                    },
                },
            ],
        },
    },
);

__PACKAGE__->setup;

1;
