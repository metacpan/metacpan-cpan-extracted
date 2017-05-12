package Chart::OFC2::Extremes;

=head1 NAME

Chart::OFC2::Extremes - OFC2 axis or chart extremes

=head1 SYNOPSIS

    use Chart::OFC2::Extremes;
    
    has 'extremes' => (
        is      => 'rw',
        isa     => 'Chart::OFC2::Extremes',
        default => sub { Chart::OFC2::Extremes->new() },
        lazy    => 1,
    );
    
    $self->extremes->reset();

=head1 DESCRIPTION

=cut

use Moose;
use Moose::Util::TypeConstraints;
use MooseX::StrictConstructor;
use Carp::Clan 'croak';

our $VERSION = '0.07';

coerce 'Chart::OFC2::Extremes'
    => from 'HashRef'
    => via { Chart::OFC2::Extremes->new($_) };

=head1 PROPERTIES

    has 'x_axis_max' => (is => 'rw', isa => 'Num|Undef', );
    has 'x_axis_min' => (is => 'rw', isa => 'Num|Undef', );
    has 'y_axis_max' => (is => 'rw', isa => 'Num|Undef', );
    has 'y_axis_min' => (is => 'rw', isa => 'Num|Undef', );
    has 'other'      => (is => 'rw', isa => 'Num|Undef', );

=cut

has 'x_axis_max' => (is => 'rw', isa => 'Num|Undef', );
has 'x_axis_min' => (is => 'rw', isa => 'Num|Undef', );
has 'y_axis_max' => (is => 'rw', isa => 'Num|Undef', );
has 'y_axis_min' => (is => 'rw', isa => 'Num|Undef', );
has 'other'      => (is => 'rw', isa => 'Num|Undef', );


=head1 METHODS

=head2 new()

Object constructor.

=head2 reset($axis_type, $values)

Calculate x or y minimal and maximal values and set (x|y)_axis_(min|max) according.

=cut

sub reset {
    my $self      = shift;
    my $axis_type = shift;
    my $values    = shift;
    
    croak 'pass axis type (x|y) argument'
        if (($axis_type ne 'y') and ($axis_type ne 'x'));
    croak 'pass values argument as array ref'
        if (ref $values ne 'ARRAY');

    my $axis_min = $axis_type.'_axis_min';
    my $axis_max = $axis_type.'_axis_max';
    
    my $max;
    my $min;
    my @values_to_check = @{$values};
    while (scalar @values_to_check) {
        my $value = shift @values_to_check;
        
        next if not defined $value;
        push @values_to_check, @{$value}
            if ref $value eq 'ARRAY';
        
        next if ref $value ne '';
        
        $max = $value
            if ((not defined $max) or ($value > $max));
        $min = $value
            if ((not defined $min) or ($value < $min));
    }
    
    $self->$axis_min($min)
        if defined $min;
    $self->$axis_max($max)
        if defined $max;
}


=head2 TO_JSON()

Returns HashRef that is possible to give to C<encode_json()> function.

=cut

sub TO_JSON {
    my $self = shift;
    
    return {
        'x_axis_max' => $self->x_axis_max,
        'x_axis_min' => $self->x_axis_min, 
        'y_axis_max' => $self->y_axis_max,
        'y_axis_min' => $self->y_axis_min,
        'other'      => $self->other,
    };
}

1;


__END__

=head1 AUTHOR

Jozef Kutej

=cut
