package Articulate::FrameworkAdapter;
use strict;
use warnings;

use Moo;

with 'Articulate::Role::Component';

use Articulate::Syntax qw(instantiate);

# Currently, only Dancer1 is supported.

has provider => (
  is      => 'rw',
  default => sub { 'Articulate::FrameworkAdapter::Dancer1' },
  coerce  => sub { instantiate(@_) },
);

1;
