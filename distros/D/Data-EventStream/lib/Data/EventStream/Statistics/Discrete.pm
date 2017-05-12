package Data::EventStream::Statistics::Discrete;
use 5.010;
use Moose;
our $VERSION = "0.13";
$VERSION = eval $VERSION;

=head1 NAME

Data::EventStream::Statistics::Discrete - basic statistical functions for the sample

=head1 VERSION

This document describes Data::EventStream::Statistics::Discrete version 0.13

=head1 SYNOPSIS

    use Data::EventStream::Statistics::Discrete;
    my $stat = Data::EventStream::Statistics::Discrete->new(
        value_sub => \&event_value,
    );
    $ev_stream->add_aggregator($stat, %params);

=head1 DESCRIPTION

Module implements aggregator that calculates basic statistical functions for
data set in aggregators' window.

=head1 METHODS

=head2 $class->new(value_sub => \&value_sub)

Create a new aggregator. Requires I<value_sub> parameter which defines
subroutine that returns numeric value for an event.

=cut

has value_sub => ( is => 'ro', required => 1, );

has _sum => ( is => 'rw', default => 0, );

has _sq_sum => ( is => 'rw', default => 0, );

has _count => ( is => 'rw', default => 0, );

=head2 $self->count

Current number of events in the window

=cut

sub count { shift->{_count} }

=head2 $self->sum

Sum of all events in the window

=cut

sub sum { shift->{_sum} }

=head2 $self->mean

Average value for the event

=cut

sub mean {
    my $self = shift;
    $self->{_count} ? $self->{_sum} / $self->{_count} : undef;
}

=head2 $self->variance

Variance of the data. Division by n-1 is used

=cut

sub variance {
    my $self  = shift;
    my $count = $self->{_count};
    return undef unless $count;
    return 0 if $count == 1;
    my $variance = ( $self->{_sq_sum} - $count * $self->mean**2 ) / ( $count - 1 );
    $variance > 0 ? $variance : 0;
}

=head2 $self->standard_deviation

Standard deviation of the data. Division by n-1 is used

=cut

sub standard_deviation {
    my $variance = shift->variance;
    defined $variance ? sqrt($variance) : undef;
}

=head1 STANDARD AGGREGATOR METHODS

=head2 $self->enter($event, $win)

Invoked when event enters window

=cut

sub enter {
    my ( $self, $event, $window ) = @_;
    my $val = $self->{value_sub}->($event);
    $self->{_sum} += $val;
    $self->{_sq_sum} += $val * $val;
    $self->{_count}++;
}

=head2 $self->leave($event, $win)

Invoked when event leaves window

=cut

sub leave {
    my ( $self, $event, $window ) = @_;
    my $val = $self->{value_sub}->($event);
    $self->{_sum} -= $val;
    $self->{_sq_sum} -= $val * $val;
    $self->{_count}--;
}

=head2 $self->reset($win)

Invoked when aggregator is reset

=cut

sub reset {
    my ( $self, $window ) = @_;
    $self->{_sum}    = 0;
    $self->{_sq_sum} = 0;
    $self->{_count}  = 0;
}

=head2 $self->window_update($win)

Invoked when window is updated

=cut

sub window_update {
    1;
}

__PACKAGE__->meta->make_immutable;

1;
