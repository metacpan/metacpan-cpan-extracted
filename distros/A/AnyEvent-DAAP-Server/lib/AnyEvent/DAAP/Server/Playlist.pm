package AnyEvent::DAAP::Server::Playlist;
use Any::Moose;

our @Attributes = qw(
    dmap_itemid dmap_persistentid dmap_itemname
);

has $_ => is => 'rw' for @Attributes;

has dmap_itemid => (
    is  => 'rw',
    isa => 'Int',
    default => sub { 0+$_[0] & 0xFFFFFF },
);

has tracks => (
    is  => 'rw',
    isa => 'ArrayRef[AnyEvent::DAAP::Server::Track]',
    default => sub { +[] },
    auto_deref => 1,
);

__PACKAGE__->meta->make_immutable;

no Any::Moose;

sub as_dmap_struct {
    my $self = shift;
    return [
        'dmap.listingitem' => [
            [ 'dmap.itemid'       => $_->dmap_itemid ],
            [ 'dmap.persistentid' => $_->dmap_persistentid ],
            [ 'dmap.itemname'     => $_->dmap_itemname ],
            [ 'com.apple.itunes.smart-playlist' => 0 ],
            [ 'dmap.itemcount'    => scalar @{ $_->tracks } ],
        ],
    ];
}

sub add_track {
    my ($self, $track) = @_;
    push @{ $self->tracks }, $track;
}

1;
