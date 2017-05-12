package Chart::OFC2::Line;

=head1 NAME

Chart::OFC2::Line - OFC2 Line chart

=head1 SYNOPSIS

    use Chart::OFC2;
    use Chart::OFC2::Axis;
    use Chart::OFC2::Line;
    
    my $chart = Chart::OFC2->new(
        'title'  => 'Line chart test',
        'x_axis' => Chart::OFC2::XAxis->new(
            'labels' => [ 'Jan', 'Feb', 'Mar', 'Apr', 'May' ],
        ),
    );
    
    my $line = Chart::OFC2::Line->new();
    $line->values([ 1..5 ]);
    $chart->add_element($line);

    print $chart->render_chart_data();

=head1 DESCRIPTION

	extends 'Chart::OFC2::BarLineBase';

=cut

use Moose;
use MooseX::StrictConstructor;

our $VERSION = '0.07';

extends 'Chart::OFC2::BarLineBase';

=head1 PROPERTIES

    has '+type_name' => (default => 'line');
    has 'width'      => (is => 'rw', isa => 'Int',);

=cut

has '+type_name' => (default => 'line');
has 'width'      => (is => 'rw', isa => 'Int',);


1;


=head1 Chart::OFC2::Line::Dot

Dotted line chart

	extends 'Chart::OFC2::Line';

=cut

package Chart::OFC2::Line::Dot;
use Moose;
use MooseX::StrictConstructor;
our $VERSION = '0.07';
extends 'Chart::OFC2::Line';

=head1 PROPERTIES

	has '+type_name' => (default => 'line_dot');
    has 'dot-size'   => (is => 'rw', isa => 'Int',);

=cut

has '+type_name' => (default => 'line_dot');
has 'dot-size'   => (is => 'rw', isa => 'Int',);


1;


=head1 Chart::OFC2::Line::Hollow

Hollow line chart

	extends 'Chart::OFC2::Line::Dot';

=cut

package Chart::OFC2::Line::Hollow;
use Moose;
use MooseX::StrictConstructor;
our $VERSION = '0.07';
extends 'Chart::OFC2::Line::Dot';

=head1 PROPERTIES

	has '+type_name' => (default => 'line_hollow');

=cut

has '+type_name' => (default => 'line_hollow');

1;


=head1 Chart::OFC2::Area::Hollow

Hollow line chart

	extends 'Chart::OFC2::Line::Dot';

=cut

package Chart::OFC2::Area::Hollow;
use Moose;
use MooseX::StrictConstructor;
our $VERSION = '0.07';
extends 'Chart::OFC2::Line::Dot';

=head1 PROPERTIES

	has '+type_name' => (default => 'area_hollow');

=cut

has '+type_name' => (default => 'area_hollow');
has 'width'      => (is => 'rw', isa => 'Int',);
has 'halo-size'  => (is => 'rw', isa => 'Int',);
has 'fill-alpha' => (is => 'rw', isa => 'Num',);
has 'fill'       => (is => 'rw', isa => 'Str',);
has 'text'       => (is => 'rw', isa => 'Str',);

1;

