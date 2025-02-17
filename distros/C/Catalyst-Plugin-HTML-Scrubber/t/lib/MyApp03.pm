package MyApp03;

use Moose;
use namespace::autoclean;

use Catalyst qw/HTML::Scrubber/;

extends 'Catalyst';

__PACKAGE__->config(
    name     => 'MyApp03',
    scrubber => {

        auto => 1,

        ignore_params => [ qr/_html$/, 'ignored_param' ],

        ignore_paths => [
            '/exempt_path_name',
            qr{/all_exempt/.+},
        ],

        # params for HTML::Scrubber
        params => [
            allow => [qw/br hr b/],
        ],
    }
);
__PACKAGE__->setup();

1;

