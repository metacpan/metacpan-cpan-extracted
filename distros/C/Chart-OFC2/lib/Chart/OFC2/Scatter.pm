package Chart::OFC2::Scatter;

=head1 NAME

Chart::OFC2::Scatter - OFC2 Scatter chart

=head1 DESCRIPTION

	extends 'Chart::OFC2::Element';

=cut

use Moose;
use MooseX::StrictConstructor;

our $VERSION = '0.07';

extends 'Chart::OFC2::Element';

=head1 PROPERTIES

	has '+type_name' => (default => 'scatter');

=cut

has '+type_name'    => (default => 'scatter');
has '+use_extremes' => (default => 1);    # scatter needs x-y min-maxes to print
has '+extremes'     => (default => sub { $_[0]->set_extremes }, lazy => 1 );    # scatter needs x-y min-maxes to print


=head1 METHODS

=head2 set_extremes()

Set the chart element extremes.

=cut

sub set_extremes {
    my ($self) = @_;
    my $extremes = {
        'x_axis_max' => undef,
        'x_axis_min' => undef,
        'y_axis_max' => undef,
        'y_axis_min' => undef,
        'other'      => undef
    };
    for (@{ $self->values }) {
        $extremes->{'y_axis_max'} = $_->{'y'} if !defined($extremes->{'y_axis_max'});
        if ($_->{'y'} > $extremes->{'y_axis_max'}) {
            $extremes->{'y_axis_max'} = $_->{'y'};
        }
        $extremes->{'y_axis_min'} = $_->{'y'} if !defined($extremes->{'y_axis_min'});
        if ($_->{'y'} < $extremes->{'y_axis_min'}) {
            $extremes->{'y_axis_min'} = $_->{'y'};
        }

        $extremes->{'x_axis_max'} = $_->{'x'} if !defined($extremes->{'x_axis_max'});
        if ($_->{'x'} > $extremes->{'x_axis_max'}) {
            $extremes->{'x_axis_max'} = $_->{'x'};
        }
        $extremes->{'x_axis_min'} = $_->{'x'} if !defined($extremes->{'x_axis_min'});
        if ($_->{'x'} < $extremes->{'x_axis_min'}) {
            $extremes->{'x_axis_min'} = $_->{'x'};
        }

    }
    $self->extremes(Chart::OFC2::Extremes->new($extremes));
}

1;
