
package Data::Feed::Web::Enclosure;

use Any::Moose;

has 'url' => (
    is => 'rw',
    isa => 'Str',
    required => 1,
);

has 'length' => (
    is => 'rw',
    isa => 'Int',
);

has 'type' => (
    is => 'rw',
    isa => 'Str',
);

__PACKAGE__->meta->make_immutable;

no Any::Moose;

1;

__END__

=head1 NAME

Data::Feed::Web::Enclosure - Module For Web-Related Feed Enclosure

=cut
