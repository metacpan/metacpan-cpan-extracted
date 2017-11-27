package Chloro::Test::Default;

use Moose;
use namespace::autoclean;

use Chloro;

use Chloro::Types qw( ArrayRef Int );

field foo => (
    isa     => Int,
    default => 42,
);

field bar => (
    isa     => ArrayRef,
    default => sub { [] },
);

group baz => (
    repetition_key => 'baz_id',
    (
        field x => (
            isa      => Int,
            required => 1,
        ),
    ),
    (
        field y => (
            isa     => ArrayRef,
            default => sub { [ $_[1], $_[2] ] },
        )
    ),
);

__PACKAGE__->meta()->make_immutable;

1;
