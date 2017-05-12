package MyApp02;

use Moose;
use namespace::autoclean;

use Catalyst qw/HTML::Scrubber/;

extends 'Catalyst';

__PACKAGE__->config(name => 'MyApp02');
__PACKAGE__->setup();

1;

