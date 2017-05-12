package Test::App;
use strict;
use warnings;

use Catalyst;    # qw/-Debug/;

our $VERSION = '0.01';
__PACKAGE__->config(
  name            => 'Test::App',
  'Model::Search' => {
    nodes           => 'localhost:9200',
    request_timeout => 30,
    max_requests    => 10_000
  }
);

__PACKAGE__->setup;
