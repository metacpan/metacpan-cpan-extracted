package Dackup::Entry;
use Moose;
use MooseX::StrictConstructor;

has 'key' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);
has 'md5_hex' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);
has 'size' => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

__PACKAGE__->meta->make_immutable;

1;
