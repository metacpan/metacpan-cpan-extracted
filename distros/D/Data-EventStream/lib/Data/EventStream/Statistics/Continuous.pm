package Data::EventStream::Statistics::Continuous;
use Moose;
our $VERSION = "0.13";
$VERSION = eval $VERSION;

=head1 NAME

Data::EventStream::Statistics::Continuous - calculate basic parameters of process

=head1 VERSION

This document describes Data::EventStream::Statistics::Continuous version 0.13

=head1 SYNOPSIS

    use Data::EventStream::Statistics::Continuous;
    my $stat = Data::EventStream::Statistics::Continuous->new(
        value_sub => \&event_value,
        time_sub  => \&event_time,
    );
    $ev_stream->add_aggregator($stat, %params);

=head1 DESCRIPTION

Module implements aggregator that calculates basic descriptive parameters of
the process defined by the set of events fitting in aggregator's window.

=head1 METHODS

=head2 $class->new(value_sub => \&value_sub, time_sub => \&time_sub)

Create a new aggregator. Requires I<value_sub> and I<time_sub> parameters
which define subroutines that return numeric value and time for an event
accordingly.

=cut

has _count => ( is => 'rw', default => 0, );

has _integral => ( is => 'rw', default => 0, );

has _start_pos => ( is => 'rw', );

has _cur_pos => ( is => 'rw', );

has time_sub => ( is => 'ro', required => 1, );

has value_sub => ( is => 'ro', required => 1, );

=head2 $self->count

Return number of events in aggregator's window

=cut

sub count { shift->{_count} }

=head2 $self->interval

Interval covered by aggregator's window

=cut

sub interval {
    my $self = shift;
    $self->{_start_pos} ? $self->{_cur_pos}[0] - $self->{_start_pos}[0] : 0;
}

=head2 $self->integral

Integral time-weighted value of the process on the interval

=cut

sub integral { shift->{_integral} }

=head2 $self->mean

Average value of the process on the interval

=cut

sub mean {
    my $self = shift;
        $self->interval     ? $self->{_integral} / $self->interval
      : $self->{_start_pos} ? $self->{_start_pos}[1]
      :                       undef;
}

=head2 $self->change

Difference between end value and entry value of the process on the interval

=cut

sub change {
    my $self = shift;
    $self->{_start_pos} ? $self->{_cur_pos}[1] - $self->{_start_pos}[1] : 0;
}

=head1 STANDARD AGGREGATOR METHODS

See description of the following methods in the documentation for L<Data::EventStream::Aggregator>.

=head2 $self->enter($event, $win)

=cut

sub enter {
    my ( $self, $event, $window ) = @_;
    my $time = $self->{time_sub}->($event);
    my $val  = $self->{value_sub}->($event);
    $self->{_start_pos} //= [ $time, $val ];
    $self->{_cur_pos} = [ $time, $val ];
    $self->{_count}++;
}

=head2 $self->leave($event, $win)

=cut

sub leave {
    my ( $self, $event, $window ) = @_;
    my $start_ev = $window->get_event(0);
    if ( defined $start_ev and $self->{time_sub}->($start_ev) == $window->{start_time} ) {
        $self->{_start_pos}[1] = $self->{value_sub}->($start_ev);
    }
    else {
        $self->{_start_pos}[1] = $self->{value_sub}->($event);
    }
    $self->{_count}--;
}

=head2 $self->reset($window)

=cut

sub reset {
    my ( $self, $window ) = @_;
    $self->{_count}    = 0;
    $self->{_integral} = 0;
    if ( $self->{_start_pos} ) {
        my $val = $self->{_cur_pos}[1];
        $self->{_start_pos} = [ $window->start_time, $val ];
        $self->{_cur_pos}[0] = $window->end_time;
    }
}

=head2 $self->window_update($window)

=cut

sub window_update {
    my ( $self, $window ) = @_;
    my $int_change = 0;
    my $start      = $self->{_start_pos};
    my $new_start  = $window->start_time;
    if ( $start and $start->[0] < $new_start ) {
        $int_change -= ( $new_start - $start->[0] ) * $start->[1];
        $start->[0] = $new_start;
    }
    if ( my $cur = $self->{_cur_pos} ) {
        my $new_cur = $window->end_time;
        $int_change += ( $new_cur - $cur->[0] ) * $cur->[1];
        $cur->[0] = $new_cur;
    }
    if ($int_change) {
        $self->{_integral} += $int_change;
    }
}

no Moose;

__PACKAGE__->meta->make_immutable;

1;
