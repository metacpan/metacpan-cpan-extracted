package Chart::OFC2::Bar;

=head1 NAME

Chart::OFC2::Bar - OFC2 bar chart

=head1 SYNOPSIS

    use Chart::OFC2;
    use Chart::OFC2::Axis;
    use Chart::OFC2::Bar;
    
    my $chart = Chart::OFC2->new(
        'title'  => 'Bar chart test',
        'x_axis' => Chart::OFC2::XAxis->new(
            'labels' => [ 'Jan', 'Feb', 'Mar', 'Apr', 'May' ],
        ),
        'y_axis' => {
            'max' => 'a',
            'min' => 'a',
        },
    );
    
    my $bar = Chart::OFC2::Bar->new();
    $bar->values([ 1..5 ]);
    $chart->add_element($bar);

    print $chart->render_chart_data();

=head1 DESCRIPTION

	extends 'Chart::OFC2::BarLineBase';

=cut

use Moose;
use MooseX::StrictConstructor;

our $VERSION = '0.07';

extends 'Chart::OFC2::BarLineBase';

=head1 PROPERTIES

	has '+type_name' => (default => 'bar');

=cut

has '+type_name' => (default => 'bar');

1;

=head1 Chart::OFC2::Bar::3D

3D bar chart

	extends 'Chart::OFC2::Bar';

=cut

package Chart::OFC2::Bar::3D;
use Moose;
use MooseX::StrictConstructor;
our $VERSION = '0.07';
extends 'Chart::OFC2::Bar';

=head1 PROPERTIES

	has '+type_name' => (default => 'bar_3d');

=cut

has '+type_name' => (default => 'bar_3d');

1;


=head1 Chart::OFC2::Bar::Fade

Fade bar chart

	extends 'Chart::OFC2::Bar';

=cut

package Chart::OFC2::Bar::Fade;
use Moose;
use MooseX::StrictConstructor;
our $VERSION = '0.07';
extends 'Chart::OFC2::Bar';

=head1 PROPERTIES

	has '+type_name' => (default => 'bar_fade');

=cut

has '+type_name' => (default => 'bar_fade');

1;


=head1 Chart::OFC2::Bar::Glass

Glass bar chart

	extends 'Chart::OFC2::Bar';

=cut

package Chart::OFC2::Bar::Glass;
use Moose;
use MooseX::StrictConstructor;
our $VERSION = '0.07';
extends 'Chart::OFC2::Bar';

=head1 PROPERTIES

	has '+type_name' => (default => 'bar_glass');

=cut

has '+type_name' => (default => 'bar_glass');

1;


=head1 Chart::OFC2::Bar::Sketch

Sketch bar chart

	extends 'Chart::OFC2::Bar';

=cut

package Chart::OFC2::Bar::Sketch;
use Moose;
use MooseX::StrictConstructor;
our $VERSION = '0.07';
extends 'Chart::OFC2::Bar';

=head1 PROPERTIES

	has '+type_name' => (default => 'bar_sketch');

=cut

has '+type_name' => (default => 'bar_sketch');

1;


=head1 Chart::OFC2::Bar::Filled

Filled bar chart

	extends 'Chart::OFC2::Bar';

=cut

package Chart::OFC2::Bar::Filled;
use Moose;
use MooseX::StrictConstructor;
our $VERSION = '0.07';
extends 'Chart::OFC2::Bar';

=head1 PROPERTIES

	has '+type_name'     => (default => 'bar_filled');
	has 'outline_collor' => (is => 'rw', isa => 'Str',);

=cut

has '+type_name'     => (default => 'bar_filled');
has 'outline_collor' => (is => 'rw', isa => 'Str',);


1;


=head1 Chart::OFC2::Bar::Stack

Stack bar chart

	extends 'Chart::OFC2::Bar';

=cut

package Chart::OFC2::Bar::Stack;
use Moose;
use MooseX::StrictConstructor;
our $VERSION = '0.07';
extends 'Chart::OFC2::Bar';

=head1 PROPERTIES

	has '+type_name' => (default => 'bar_stack');
	has 'text'       => (is => 'rw', isa => 'Str',);

=cut

has '+type_name' => (default => 'bar_stack');
has 'text'       => (is => 'rw', isa => 'Str',);

1;
