package Chart::OFC2::HBar;

=head1 NAME

Chart::OFC2::HBar - OFC2 horizontal bar chart

=head1 SYNOPSIS

    my $chart = Chart::OFC2->new(
        'title'  => 'HBar chart test',
        'y_axis' => Chart::OFC2::YAxis->new(
            'labels' => [ 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun' ],
            'offset' => 1,
        ),
        'tooltip' => {
            'mouse' => 2,
        },
    );
    
    my $hbar = Chart::OFC2::HBar->new(
        'values' => [ { 'left' => 1.5, 'right' => 3, }, 1, 2, 3, 4, 5, ],
        'colour' => '#40FF0D',
    );

    print $chart->render_chart_data();

=head1 DESCRIPTION

	extends 'Chart::OFC2::BarLineBase';

In L<Chart::OFC2::HBarValues> when converting values to JSON the values are
reversed. This is done so that the C<y_axis->labels> match to the values.
Also note that the C<y_axis->offset> is set to one so that the label is
in the middle of the bar.

=cut

use Moose;
use MooseX::StrictConstructor;

our $VERSION = '0.07';

extends 'Chart::OFC2::BarLineBase';

use Chart::OFC2::HBarValues;

=head1 PROPERTIES

	has '+type_name' => (default => 'hbar');

=cut

has '+type_name' => (default => 'hbar');
has 'values'     => (is => 'rw', isa => 'Chart::OFC2::HBarValues', 'coerce' => 1,);

1;
