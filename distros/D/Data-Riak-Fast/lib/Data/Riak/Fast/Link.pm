package Data::Riak::Fast::Link;

use Mouse;

use URL::Encode qw/url_encode url_decode/;
use HTTP::Headers::ActionPack::LinkHeader;

has bucket => (
    is => 'ro',
    isa => 'Str',
    required => 1
);

has key => (
    is => 'ro',
    isa => 'Str',
    predicate => 'has_key'
);

has riaktag => (
    is => 'ro',
    isa => 'Str',
    predicate => 'has_riaktag'
);

has params => (
    is => 'ro',
    isa => 'HashRef',
    default => sub { +{} }
);

sub from_link_header {
    my ($class, $link_header) = @_;

    my ($bucket, $key, $riaktag);

    # link to another key in riak
    if ($link_header->href =~ /^\/buckets\/(.*)\/keys\/(.*)/) {
        ($bucket, $key) = ($1, $2);
    }
    # link to a bucket
    elsif ($link_header->href =~ /^\/buckets\/(.*)/) {
        $bucket = $1;
    }
    else {
        confess "Incompatible link header URL (" .  $link_header->href . ")";
    }

    my %params = %{ $link_header->params };

    $riaktag = url_decode( delete $params{'riaktag'} )
        if exists $params{'riaktag'};

    $class->new(
        bucket => $bucket,
        ($key ? (key => $key) : ()),
        ($riaktag ? (riaktag => $riaktag) : ()),
        params => \%params
    );
}

sub as_link_header {
    my $self = shift;
    if ($self->has_key) {
        return HTTP::Headers::ActionPack::LinkHeader->new(
            sprintf('/buckets/%s/keys/%s', $self->bucket, $self->key),
            ($self->has_riaktag ? (riaktag => url_encode($self->riaktag)) : ()),
            %{ $self->params }
        );
    }
    else {
        return HTTP::Headers::ActionPack::LinkHeader->new(
            sprintf('/buckets/%s', $self->bucket),
            ($self->has_riaktag ? (riaktag => url_encode($self->riaktag)) : ()),
            %{ $self->params }
        );
    }
}


__PACKAGE__->meta->make_immutable;
no Mouse;

1;

__END__
