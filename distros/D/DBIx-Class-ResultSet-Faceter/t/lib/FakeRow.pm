package #
    FakeRow;
use Moose;
use DateTime;

has 'name_last' => (
    is => 'rw',
    isa => 'Str',
);

has 'date_created' => (
    is => 'rw',
    isa => 'DateTime',
    default => sub { DateTime->now }
);

1;