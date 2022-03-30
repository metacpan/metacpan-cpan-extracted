package Dancer2::Plugin::FormValidator::Result;

use Moo;
use Types::Standard qw(ArrayRef HashRef Bool Str Undef);
use namespace::clean;

has success => (
    is       => 'ro',
    isa      => Bool,
    required => 1,
);

has missing => (
    is       => 'ro',
    isa      => ArrayRef,
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
    isa      => Undef | Str | HashRef,
    required => 1,
);

1;
