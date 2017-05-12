package Test::Data::ArrayList::Class;

use Moose;
use Data::Clone qw( data_clone );

has 'store' => (
    is => 'rw',
    isa => 'HashRef',
    default => sub { { key => 'value' } },
);

has 'idx' => (
    is => 'rw',
    isa => 'Int',
);


sub clone {
    my $self = shift;

    return data_clone($self);
};

1;

