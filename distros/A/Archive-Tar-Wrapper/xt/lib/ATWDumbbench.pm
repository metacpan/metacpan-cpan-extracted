package ATWDumbbench;
use strict;
use warnings;
use parent 'Dumbbench';

sub new {
    my ( $class, @args ) = @_;
    my $self = $class->SUPER::new(@args);
    $self->{atw_measure_map} = {};
    return $self;
}

sub measurements {
    my $self = shift;
    return ( sort { $a <=> $b } values( %{ $self->{atw_measure_map} } ) )[0];
}

sub get_measure {
    my ( $self, $name ) = @_;
    return $self->{atw_measure_map}->{$name};
}

sub get_map {
    my ($self) = @_;
    return $self->{atw_measure_map};
}

sub report_as_text {
    my ($self) = @_;
    my $formatted;

    foreach my $instance ( $self->instances ) {
        my $result     = $instance->result;
        my $result_str = Dumbbench::unscientific_notation($result);

        my $mean  = $result->raw_number;
        my $sigma = $result->raw_error->[0];
        my $name  = $instance->_name_prefix;

        $self->{atw_measure_map}->{ $instance->name } = $result->number;

        $formatted .= sprintf(
            "%sRan %u iterations (%u outliers).\n",
            $name,
            scalar( @{ $instance->timings } ),
            scalar( @{ $instance->timings } ) - $result->nsamples
        );

        $formatted .=
          sprintf( "%sRounded run time per iteration: %s (%.1f%%)\n",
            $name, $result_str, $sigma / $mean * 100 );
    }

    return $formatted;
}

1;
