package Catmandu::Store::RKD::API::Search;

use Moo;
use LWP::UserAgent;

use Catmandu::Sane;

use Catmandu::Store::RKD::API::Parse;
use Catmandu::Store::RKD::API::Extract;

has url => (is => 'ro', required => 1);

has engine   => (is => 'lazy');
has results  => (is => 'lazy');

sub _build_engine {
    my $self = shift;
    my $engine = LWP::UserAgent->new();
    return $engine;
}

sub _build_results {
    my $self = shift;
    my $items_raw = $self->__search();
    my $items = [];
    
    # The results are in $items_raw->{'items'}
    my $parser = Catmandu::Store::RKD::API::Parse->new(results => $items_raw);
    my $parsed_items = $parser->items;
    push @{$items}, @{$parsed_items->{'items'}};

    # The API paginates, but we want all the results. So continue as long as there are items
    while ($parsed_items->{'total'} > $parsed_items->{'start'} * $parsed_items->{'per_page'}) {

        my $startIndex = $parsed_items->{'start'} + $parsed_items->{'per_page'};
        $items_raw = $self->__search($startIndex);

        $parser = Catmandu::Store::RKD::API::Parse->new(results => $items_raw);
        $parsed_items = $parser->items;

        push @{$items}, @{$parsed_items->{'items'}};
    }

    # Return [{
    #    guid        => foo,
    #    title       => bar,
    #    description => biz,
    #    artist_link => xyz
    #}]
    my $extracter = Catmandu::Store::RKD::API::Extract->new(results => $items);
    return $extracter->items;
}

##
# Query the API
sub __search {
    my ($self, $startIndex) = @_;
    my $url;
    if (defined($startIndex)) {
        my $template = '%s&startIndex=%s';
        $url = sprintf($template, $self->url, $startIndex);
    } else {
        $url = $self->url;
    }
    my $response = $self->engine->get($url);
    if ($response->is_success) {
        return $response->decoded_content;
    } else {
        Catmandu::HTTPError->throw({
                code             => $response->code,
                message          => $response->status_line,
                url              => $response->request->uri,
                method           => $response->request->method,
                request_headers  => [],
                request_body     => $response->request->decoded_content,
                response_headers => [],
                response_body    => $response->decoded_content,
            });
        return undef;
    }
}

1;