package MyApp03;

use Moose;
use namespace::autoclean;

use Catalyst qw/HTML::Scrubber/;

extends 'Catalyst';

__PACKAGE__->config(
    name     => 'MyApp03',
    scrubber => [allow => [qw/br hr b/],]

);
__PACKAGE__->setup();

1;

