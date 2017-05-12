package Data::EventStream::Window;
use 5.010;
our $VERSION = "0.13";
$VERSION = eval $VERSION;
use Carp;

=head1 NAME

Data::EventStream::Window - Perl extension for event processing

=head1 VERSION

This document describes Data::EventStream::Window version 0.13

=head1 DESCRIPTION

This class represents time window for which aggregator aggregates data.
Normally window objects are passed to aggregators' callbacks and user has no need to build them himself.

=head1 METHODS

=cut

=head2 $class->new

Create a new Window object. L<Data::EventStream> will do it for you.

=cut

sub new {
    my $class = shift;
    my $self  = {@_};
    $self->{count} //= 0;
    croak "events parameter is required" unless $self->{events};
    $self->{start_time} //= 0;
    $self->{end_time}   //= 0;
    return bless $self, $class;
}

=head2 $self->count

Number of events in the window

=cut

sub count { shift->{count} }

=head2 $self->start_time

Window start time

=cut

sub start_time { shift->{start_time} }

=head2 $self->end_time

Window end time

=cut

sub end_time { shift->{end_time} }

=head2 $self->reset_count

Set number of events in window to 0

=cut

sub reset_count {
    shift->{count} = 0;
}

=head2 $self->time_length

Window length in time

=cut

sub time_length {
    my $self = shift;
    return $self->{end_time} - $self->{start_time};
}

=head2 $self->get_event($idx)

Returns event with the specified index. 0 being the oldest, and -1 being the
latest, most recent, event.

=cut

sub get_event {
    my ( $self, $idx ) = @_;
    my $count = $self->{count};
    return if $idx >= $count or $idx < -$count;
    if ( $idx >= 0 ) {
        return $self->{events}[ -( $count + $idx ) ];
    }
    else {
        return $self->{events}[$idx];
    }
}

=head2 $self->get_iterator

Returns callable iterator object. Each time you call it, it returns the next
event starting from the oldest one. For example:

    my $next_event = $win->get_iterator;
    while ( my $event = $next_event->() ) {
        ...
    }

=cut

sub get_iterator {
    my $self   = shift;
    my $idx    = -$self->{count};
    my $events = $self->{events};
    return sub {
        return unless $idx < 0;
        return $events->[ $idx++ ];
    };
}

sub _shift_event {
    my ($self) = @_;
    $self->{count}--;
    return $self->{events}[ -( $self->count + 1 ) ];
}

sub _push_event {
    my ($self) = @_;
    $self->{count}++;
    return $self->{events}[ -(1) ];
}

1;
