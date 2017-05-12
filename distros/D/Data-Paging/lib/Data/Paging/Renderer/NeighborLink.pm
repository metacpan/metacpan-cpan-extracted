package Data::Paging::Renderer::NeighborLink;
use common::sense;

use parent 'Data::Paging::Renderer::Base';

sub render {
    my ($self, $collection) = @_;

    return +{
        entries      => $collection->sliced_entries,
        has_next     => $collection->has_next,
        has_prev     => $collection->has_prev,
        next_page    => $collection->next_page,
        current_page => $collection->current_page,
        prev_page    => $collection->prev_page,
        begin_count  => $collection->begin_count,
        end_count    => $collection->end_count,
        base_url     => $collection->base_url,
    };
}

1;
