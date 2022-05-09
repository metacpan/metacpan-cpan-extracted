package Dancer2::Plugin::FormValidator::Result;

use strict;
use warnings;

use Moo;
use Types::Standard qw(ArrayRef HashRef Bool);
use namespace::clean;

has success => (
    is       => 'ro',
    isa      => Bool,
    required => 1,
);

has invalid => (
    is       => 'ro',
    isa      => ArrayRef,
    required => 1,
);

has valid => (
    is       => 'ro',
    isa      => HashRef,
    required => 1,
);

has messages => (
    is       => 'ro',
    isa      => HashRef,
    required => 1,
);

1;
