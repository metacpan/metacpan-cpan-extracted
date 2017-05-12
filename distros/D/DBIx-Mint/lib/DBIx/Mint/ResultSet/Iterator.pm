package DBIx::Mint::ResultSet::Iterator;

use Moo;

has closure => ( is => 'ro', required => 1 );

sub next {
    my $self = shift;
    return $self->closure->();
}

1;
