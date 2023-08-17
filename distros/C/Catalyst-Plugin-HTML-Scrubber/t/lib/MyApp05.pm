package MyApp05;

use Moose;
use namespace::autoclean;

use Catalyst qw/HTML::Scrubber/;

extends 'Catalyst';

__PACKAGE__->config(
    name     => 'MyApp03',
    scrubber => {
        ignore_params => [
            qr/_html$/,
            'ignored_param',
        ],
    },
);
__PACKAGE__->setup();

1;

