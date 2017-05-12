package Catmandu::RKD::API::Parse;

use Moo;
use XML::Struct qw(readXML);

use Catmandu::Sane;

has results => (is => 'ro', required => 1);

has items   => (is => 'lazy');

sub _build_items {
    my $self = shift;
    return $self->parse($self->results);
}

##
# Parse the result. Contains the items, but also the total amount of results,
# the items per page and the starting item. This allows you to paginate through
# the API.
sub parse {
    my ($self, $results) = @_;
    my $tree = readXML($results, simple => 1);
    my $items = $tree->{'channel'}->{'item'};
    if (ref($items) ne ref([])) {
        $items = [$items];
    }
    my $total = $tree->{'channel'}->{'opensearch:totalResults'};
    my $per_page = $tree->{'channel'}->{'opensearch:itemsPerPage'};
    my $start = $tree->{'channel'}->{'opensearch:startIndex'};
    return {
        'items'    => $items,
        'total'    => $total,
        'per_page' => $per_page,
        'start'    => $start
    };
}

1;