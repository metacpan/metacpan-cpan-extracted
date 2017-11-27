package Chloro::Test::Address;

use Moose;
use namespace::autoclean;

use Chloro;

use Chloro::Types qw( Bool Str );

field allows_mail => (
    isa     => Bool,
    default => 1,
);

group address => (
    repetition_key => 'address_id',
    (
        field street1 => (
            isa      => Str,
            required => 1,
        ),
    ),
    (
        field street2 => (
            isa => Str,
        ),
    ),
    (
        field city => (
            isa      => Str,
            required => 1,
        ),
    ),
    (
        field state => (
            isa      => Str,
            required => 1,
        ),
    ),
);

__PACKAGE__->meta()->make_immutable;

1;
