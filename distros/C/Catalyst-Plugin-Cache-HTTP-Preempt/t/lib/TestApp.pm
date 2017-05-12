package TestApp;
use Moose;
use namespace::autoclean;

use Catalyst qw/
  Cache::HTTP::Preempt
/;

extends 'Catalyst';

__PACKAGE__->setup;

1;
