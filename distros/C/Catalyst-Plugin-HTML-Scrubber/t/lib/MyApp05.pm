package MyApp05;

use Moose;
use namespace::autoclean;

use Catalyst qw/HTML::Scrubber/;

extends 'Catalyst';

__PACKAGE__->config(
    name     => 'MyApp03',
    scrubber => {

        auto => 1,

        ignore_params => [ qr/_html$/, 'ignored_param' ],

        # params for HTML::Scrubber
        params => [
            allow => [qw/br hr b/],
        ],
    }
);



__PACKAGE__->setup();
1;

