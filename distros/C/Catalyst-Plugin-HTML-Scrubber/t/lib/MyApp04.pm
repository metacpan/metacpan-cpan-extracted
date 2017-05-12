package MyApp04;

use Moose;
use namespace::autoclean;

use Catalyst qw/HTML::Scrubber/;

extends 'Catalyst';

__PACKAGE__->config(
    name     => 'MyApp04',
    scrubber => {
        auto   => 0,
        params => [
            allow => [qw/br hr b/],
        ]
        }

);
__PACKAGE__->setup();

1;

