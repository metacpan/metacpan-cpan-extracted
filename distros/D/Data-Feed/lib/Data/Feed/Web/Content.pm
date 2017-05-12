package Data::Feed::Web::Content;
use Any::Moose;

has 'type' => (
    is => 'rw',
    isa => 'Str',
);

has 'body' => (
    is => 'rw',
    isa => 'Str',
);

__PACKAGE__->meta->make_immutable;

no Any::Moose;

1;

__END__

=head1 NAME

Data::Feed::Web::Content - Role For Web-Related Feed Entry Content

=cut
