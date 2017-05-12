package Data::Riak::Fast::HTTP::Request;

use Mouse;

use HTTP::Headers::ActionPack::LinkList;

has method => (
    is => 'ro',
    isa => 'Str',
    default => 'GET'
);

has uri => (
    is => 'ro',
    isa => 'Str',
    required => 1
);

has query => (
    is => 'ro',
    isa => 'HashRef',
    predicate => 'has_query'
);

has data => (
    is => 'ro',
    isa => 'Str',
    default => ''
);

has links => (
    is => 'ro',
    isa => 'HTTP::Headers::ActionPack::LinkList',
    # TODO: make this coerce
    default => sub {
        return HTTP::Headers::ActionPack::LinkList->new;
    }
);

has indexes => (
    is => 'ro',
    isa => 'ArrayRef[HashRef]'
);

has content_type => (
    is => 'ro',
    isa => 'Str',
    default => 'text/plain'
);

has accept => (
    is => 'ro',
    isa => 'Str',
    default => '*/*'
);

__PACKAGE__->meta->make_immutable;
no Mouse;

1;

__END__
