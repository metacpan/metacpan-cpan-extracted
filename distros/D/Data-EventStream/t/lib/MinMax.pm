package MinMax;
use Moose;
with 'Data::EventStream::Aggregator';

has value_sub => (
    is      => 'ro',
    default => sub {
        sub { $_[0]->{val} }
    },
);

has max => ( is => 'ro', writer => '_set_max', default => 'NaN', );

has min => ( is => 'ro', writer => '_set_min', default => 'NaN', );

has since => ( is => 'ro', writer => '_set_since', default => 0, );

sub value {
    my $self = shift;
    return join ",", $self->min, $self->max, $self->since;
}

sub enter {
    my ( $self, $event, $window ) = @_;
    my $value = $self->value_sub->($event);
    if ( $self->max ne 'NaN' ) {
        if ( $value > $self->max ) {
            $self->_set_max($value);
        }
        elsif ( $value < $self->min ) {
            $self->_set_min($value);
        }
    }
    else {
        $self->_set_max($value);
        $self->_set_min($value);
        $self->_set_since( $window->start_time );
    }
}

sub reset {
    my ( $self, $window ) = @_;
    $self->_set_max('NaN');
    $self->_set_min('NaN');
    $self->_set_since( $window->start_time );
}

sub leave {
    my ( $self, $event, $window ) = @_;
    my $value = $self->value_sub->($event);
    $self->_set_since( $window->start_time );
    if ( $window->count == 0 ) {
        $self->_set_max('NaN');
        $self->_set_min('NaN');
    }
    elsif ( $value >= $self->max or $value <= $self->min ) {
        my $vs   = $self->value_sub;
        my $min  = my $max = $vs->( $window->get_event(-1) );
        my $next_event = $window->get_iterator;
        while ( my $event = $next_event->() ) {
            my $val = $vs->($event);
            if ( $val < $min ) {
                $min = $val;
            }
            elsif ( $val > $max ) {
                $max = $val;
            }
        }
        $self->_set_max($max);
        $self->_set_min($min);
    }
}

sub window_update {
    my ( $self, $window ) = @_;
    $self->_set_since( $window->start_time );
}

no Moose;

__PACKAGE__->meta->make_immutable;

1;
