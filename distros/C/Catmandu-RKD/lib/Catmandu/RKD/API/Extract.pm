package Catmandu::RKD::API::Extract;

use Moo;

use Catmandu::Sane;

has results => (is => 'ro', required => 1);

has items   => (is => 'lazy');

sub _build_items {
    my $self = shift;
    return $self->extract($self->results);
}

sub __extract {
    my ($self, $item) = @_;
    return {
        'guid'        => $item->{'guid'}->{'content'},
        'artist_link' => $item->{'link'},
        'title'       => $item->{'title'},
        'description' => $item->{'description'}
    };
}

sub extract {
    my ($self, $items) = @_;
    my $extracted = [];
    foreach my $item (@{$items}) {
        push @{$extracted}, $self->__extract($item);
    }
    return $extracted;
}

1;