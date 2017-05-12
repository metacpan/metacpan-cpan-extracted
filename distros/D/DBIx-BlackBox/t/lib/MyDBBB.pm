package MyDBBB;

use Moose;
use namespace::autoclean;

with 'DBIx::BlackBox' => {
    connect_info => [
        'dbi:Sybase:server=sqlserver',
        'username',
        'password',
        {
            RaiseError => 1,
            PrintError => 0,
        }
    ]
};

has 'loaded' => (
    is => 'rw',
    isa => 'Bool',
    default => 0,
);

sub BUILD {
    my $self = shift;

    $self->loaded( 1 );
}

__PACKAGE__->meta->make_immutable;

1;

