package #
    FakeResultSet;
use Moose;

use MooseX::Iterator;

has 'rows' => (
    is => 'rw',
    isa => 'ArrayRef',
    default => sub { [] }
);

has 'iterator' => (
    is => 'rw',
    isa => 'MooseX::Iterator::Array',
    lazy => 1,
    default => sub { MooseX::Iterator::Array->new(collection => $_[0]->rows) },
    clearer => 'reset',
    handles => { next => 'next' }
);

1;