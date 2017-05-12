package Data::Paging::Renderer::NavigationBar;
use common::sense;

use parent 'Data::Paging::Renderer::Base';

sub render {
    my ($self, $collection) = @_;

    return +{
        entries               => $collection->sliced_entries,
        has_prev              => $collection->has_prev,
        has_next              => $collection->has_next,
        prev_page             => $collection->prev_page,
        next_page             => $collection->next_page,
        current_page          => $collection->current_page,
        total_count           => $collection->total_count,
        begin_count           => $collection->begin_count,
        end_count             => $collection->end_count,
        base_url              => $collection->base_url,
        begin_navigation_page => $collection->begin_navigation_page,
        end_navigation_page   => $collection->end_navigation_page,
        navigation            => [
            map { +{ page_number => $_} } @{$collection->navigation}
        ],
    };
}

1;
