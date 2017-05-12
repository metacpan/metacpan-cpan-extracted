package TimeAverager;
use strict;
use warnings;

sub new {
    my ( $class, $params ) = @_;
    $params = {%$params};
    $params->{time_value_sub} //= sub { ( $_[0]->{time}, $_[0]->{val} ) };
    $params->{_sum} = 0;
    return bless $params, $class;
}

sub duration {
    my ($self) = @_;
    $self->{_start_point} ? $self->{_end_point}[0] - $self->{_start_point}[0] : 0;
}

sub value {
    my ($self) = @_;
        $self->duration ? 0 + sprintf( "%.6g", $self->{_sum} / $self->duration )
      : $self->{_start_point} ? $self->{_start_point}[1]
      :                         'NaN';
}

sub enter {
    my ( $self, $event, $win ) = @_;
    my ( $time, $value ) = $self->{time_value_sub}->($event);
    $self->{_end_point} = [ $time, $value ];
    unless ( $self->{_start_point} ) {

        # this is the first event we've got
        $self->{_start_point} = [ $time, $value ];
    }
}

sub leave {
    my ( $self, $event, $win ) = @_;
    my ( $time, $value ) = $self->{time_value_sub}->($event);
    $self->{_start_point} = [ $win->start_time, $value ];
}

sub reset {
    my ( $self, $win ) = @_;
    $self->{_sum}          = 0;
    $self->{_start_point}  = [ $win->start_time, $self->{_end_point}[1] ];
    $self->{_end_point}[0] = $win->end_time;
}

sub window_update {
    my ( $self, $win ) = @_;

    # return if we didn't receive a single event yet
    return unless $self->{_start_point};
    if ( $win->start_time > $self->{_start_point}[0] ) {
        $self->{_sum} -=
          ( $win->start_time - $self->{_start_point}[0] ) * $self->{_start_point}[1];
        $self->{_start_point}[0] = $win->start_time;
    }
    if ( $win->end_time > $self->{_end_point}[0] ) {
        $self->{_sum} +=
          ( $win->end_time - $self->{_end_point}[0] ) * $self->{_end_point}[1];
        $self->{_end_point}[0] = $win->end_time;
    }
}

1;
