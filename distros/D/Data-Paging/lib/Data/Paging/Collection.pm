package Data::Paging::Collection;
use common::sense;

use Class::Accessor::Lite (
    new => 0,
    ro  => [qw/
        entries
        total_count
        per_page
        current_page
        base_url
        window
    /],
    rw  => [qw/renderer/],
);

use Carp qw/croak/;
use POSIX qw/ceil/;

sub new {
    my ($class, %args) = @_;
    bless \%args, $class;
}

sub render {
    my $self = shift;
    croak "don't set renderer" unless $self->renderer;
    $self->renderer->render($self);
}

sub sliced_entries {
    my $self = shift;
    scalar(@{$self->entries}) > $self->per_page ?
        [@{$self->entries}[0..($self->per_page-1)]] : $self->entries;
}

sub current_visit_count {
    my $self = shift;
    scalar(@{$self->sliced_entries});
}

sub already_visited_count {
    my $self = shift;
    $self->per_page * ($self->current_page - 1)
}

sub visited_count {
    my $self = shift;
    $self->already_visited_count + $self->current_visit_count;
}

sub begin_count {
    my $self = shift;
    $self->already_visited_count + 1;
}

sub begin_position {
    my $self = shift;
    1;
}

sub end_count {
    my $self = shift;
    $self->visited_count;
}

sub end_position {
    my $self = shift;
    scalar(@{$self->sliced_entries});
}

sub begin_entry {
    my $self = shift;
    $self->sliced_entries->[$self->begin_position];
}

sub end_entry {
    my $self = shift;
    $self->sliced_entries->[$self->end_position];
}

sub first_page {
    my $self = shift;
    1;
}

sub last_page {
    my $self = shift;
    croak "can't calc last_page without total_count" unless defined $self->total_count;
    ceil($self->total_count / $self->per_page);
}

sub has_prev {
    my $self = shift;
    $self->current_page > $self->first_page;
}

sub prev_page {
    my $self = shift;
    $self->current_page - 1;
}

sub has_next {
    my $self = shift;
    $self->total_count ? $self->current_page < $self->last_page
        : scalar(@{$self->entries}) > $self->per_page;
}

sub next_page {
    my $self = shift;
    $self->current_page + 1;
}

# inspired from Data::Page::Navigation
sub navigation {
    my $self = shift;
    croak "can't calc navigation without window" unless defined $self->window;
    return [$self->first_page..$self->last_page] if $self->last_page <= $self->window;

    my @navigation = ($self->current_page);
    my $prev = $self->prev_page;
    my $next = $self->next_page;
    my $i = 0;
    while (@navigation < $self->window) {
        if ($i % 2) {
            unshift @navigation, $prev if $self->first_page <= $prev;
            $prev -= 1;
        }
        else {
            push @navigation, $next if $self->last_page >= $next;
            $next += 1;
        }
        $i += 1;
    }
    $self->{_navigation} = \@navigation;
}

sub begin_navigation_page {
    my $self = shift;
    my $navigation = $self->navigation;
    shift @{$navigation};
}

sub end_navigation_page {
    my $self = shift;
    my $navigation = $self->navigation;
    pop @{$navigation};
}

1;
