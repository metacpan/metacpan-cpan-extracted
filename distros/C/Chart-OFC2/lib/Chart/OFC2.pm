package Chart::OFC2;

=encoding utf8

=head1 NAME

Chart::OFC2 - Generate html and data files for use with Open Flash Chart version 2

=head1 SYNOPSIS

OFC2 html:

    use Chart::OFC2;
    
    my $chart = Chart::OFC2->new(
        'title'  => 'Bar chart test',
    );
    print $chart->render_swf(600, 400, 'chart-data.json', 'test-chart');

OFC2 bar chart data:

    use Chart::OFC2;
    use Chart::OFC2::Axis;
    use Chart::OFC2::Bar;
    
    my $chart = Chart::OFC2->new(
        'title'  => 'Bar chart test',
        x_axis => {
            labels => {
                labels => [ 'Jan', 'Feb', 'Mar', 'Apr', 'May' ],
            }
        },
    );
    
    my $bar = Chart::OFC2::Bar->new();
    $bar->values([ 1..5 ]);
    $chart->add_element($bar);

    print $chart->render_chart_data();

=head1 WARNING

Current version implements just subset of functionality that Open Flash
Chart 2 is offering. But it should help you to starting creating OFC2
graphs quite fast. The JSON format is quite intuitive and can be created
from any hash. This module is more like guideline.

This is early version B<PROTOTYPE> so the API B<WILL> change, be careful when upgrading
versions.

=head1 DESCRIPTION

OFC2 is a flash script for creating graphs. To have a graph we need an
F<open-flash-chart.swf> and a JSON data file describing graph data.
Complete examples you can find after successful run of this module
tests in F<t/output/> folder - F<t/output/bar.html>, F<t/output/pie.html>,
F<t/output/hbar.html> are html graphs and F<t/output/bad-data.json>,
F<t/output/pie-data.json>, F<t/output/hbar-data.json> are the data files.

=cut


use Moose;
use Moose::Util::TypeConstraints;
use MooseX::StrictConstructor;
use MooseX::Aliases;

our $VERSION = '0.07';

use Carp::Clan 'croak';
use JSON::XS qw();

use Chart::OFC2::Axis;
use Chart::OFC2::Bar;
use Chart::OFC2::Title;
use Chart::OFC2::Extremes;
use Chart::OFC2::ToolTip;
use List::Util 'min', 'max';
use List::MoreUtils 'any';

=head1 PROPERTIES

    has 'data_load_type' => (is => 'rw', isa => 'Str',  default => 'inline_js');
    has 'bootstrap'      => (is => 'rw', isa => 'Bool', default => '1');
    has 'title'          => (is => 'rw', isa => 'Chart::OFC2::Title', default => sub { Chart::OFC2::Title->new() }, lazy => 1, coerce  => 1);
    has 'x_axis'         => (is => 'rw', isa => 'Chart::OFC2::XAxis', default => sub { Chart::OFC2::XAxis->new() }, lazy => 1,);
    has 'y_axis'         => (is => 'rw', isa => 'Chart::OFC2::YAxis', default => sub { Chart::OFC2::YAxis->new() }, lazy => 1, );
    has 'elements'       => (is => 'rw', isa => 'ArrayRef', default => sub{[]}, lazy => 1);
    has 'extremes'       => (is => 'rw', isa => 'Chart::OFC2::Extremes',  default => sub { Chart::OFC2::Extremes->new() }, lazy => 1);
    has 'tooltip'        => (is => 'rw', isa => 'Chart::OFC2::ToolTip',);
    has 'bg_colour'      => (is => 'rw', isa => 'Str',  default => 'f8f8d8', alias => 'bg_color' );

=cut

has 'data_load_type' => (is => 'rw', isa => 'Str',  default => 'inline_js');
has 'bootstrap'      => (is => 'rw', isa => 'Bool', default => '1');
has 'title'          => (is => 'rw', isa => 'Chart::OFC2::Title', default => sub { Chart::OFC2::Title->new() }, lazy => 1, coerce  => 1);
has 'x_axis'         => (is => 'rw', isa => 'Chart::OFC2::XAxis', default => sub { Chart::OFC2::XAxis->new() }, lazy => 1, coerce  => 1);
has 'y_axis'         => (is => 'rw', isa => 'Chart::OFC2::YAxis', default => sub { Chart::OFC2::YAxis->new() }, lazy => 1, coerce  => 1);
has 'elements'       => (is => 'rw', isa => 'ArrayRef', default => sub{[]}, lazy => 1);
has 'extremes'       => (is => 'rw', isa => 'Chart::OFC2::Extremes',  default => sub { Chart::OFC2::Extremes->new() }, lazy => 1);
has '_json'          => (is => 'rw', isa => 'Object',  default => sub { JSON::XS->new->pretty(1)->convert_blessed(1) }, lazy => 1);
has 'tooltip'        => (is => 'rw', isa => 'Chart::OFC2::ToolTip', coerce  => 1);
has 'bg_colour'      => (is => 'rw', isa => 'Str',  default => 'f8f8d8', alias => 'bg_color' );

=head1 METHODS

=head2 new()

Object constructor.

=head2 get_element($type)

Returns new chart object of selected type. Currently only C<bar> and C<pie>
is available.

=cut

# elements are the data series items, usually containing values to plot
sub get_element {
    my ($self, $element_name) = @_;
    
    my $element_module = (
          $element_name eq 'bar' ? 'Chart::OFC2::Bar'
        : $element_name eq 'pie' ? 'Chart::OFC2::Pie'
        : undef
    );
    croak 'unsupported element - ', $element_name
        if not defined $element_name;
    
    return $element_module->new();
}


=head2 add_element($element)

Adds passed element to the graph.

=cut

sub add_element {
    my ($self, $element) = @_;
    
    if ($element->use_extremes) {
        $self->y_axis->max('a');
        $self->y_axis->min('a');
        $self->x_axis->max('a');
        $self->x_axis->min('a');
    }
    
    push(@{ $self->elements }, $element);
}


=head2 render_chart_data

Returns stringified JSON encoded graph data.

=cut

sub render_chart_data {
    my $self = shift;

    $self->auto_extremes();
    
    return $self->_json->encode({
        'title'    => $self->title,
        'x_axis'   => $self->x_axis,
        'y_axis'   => $self->y_axis,
        'tooltip'  => $self->tooltip,
        'elements' => $self->elements,
        'bg_colour' => $self->bg_colour,
    });
}


=head2 auto_extremes 

Recalculate graph auto extremes.

=cut

sub auto_extremes {
    my $self = shift;
        
    foreach my $axis_name ('x_axis', 'y_axis') {
        my $axis = $self->$axis_name;
        next if not defined $axis;
        
        foreach my $axis_type ('min', 'max') {
            my $axis_value = $axis->$axis_type;
            if ((defined $axis_value) and ($axis_value eq 'a')) {
                $axis->$axis_type($self->smooth($axis_name, $axis_type));
            }
        }
    }
    
    return;
}


=head2 render_swf($width, $height, $data_url, $div_id)

Returns html snippet that will represent one graph in a html document.

WARN: the arguments format will change to C<key => value> in the next
releases.

=cut

sub render_swf {
    my ($self, $width, $height, $data_url, $div_id) = @_;
    
    $div_id ||= 'my_chart';

    my $html = '';

    if ($self->data_load_type eq 'inline_js') {
        if ($self->bootstrap) {
            $html .= '<script type="text/javascript" src="swfobject.js"></script>';
            $self->{'skip_bootstrap'} = 1;
        }
        $html .= qq^
            <div id="$div_id"></div>
            <script type="text/javascript">
                swfobject.embedSWF(
                    "open-flash-chart.swf", "$div_id", "$width", "$height",
                    "9.0.0", "expressInstall.swf",
                    {"data-file":"$data_url"}
                );
            </script>
        ^;
    }
    else {
        $html .= qq^
            <object
                classid="clsid:d27cdb6e-ae6d-11cf-96b8-444553540000"
                codebase="http://fpdownload.macromedia.com/pub/shockwave/cabs/flash/swflash.cab#version=8,0,0,0"
                width="$width"
                height="$height"
                id="graph_2"
                align="middle">
            <param name="allowScriptAccess" value="sameDomain" />
            <param name="movie" value="open-flash-chart.swf?width=$width&height=$height&data=$data_url"/>
            <param name="quality" value="high" />
            <param name="bgcolor" value="#FFFFFF" />
            <embed
                src="open-flash-chart.swf?width=$width&height=$height&data=$data_url"
                quality="high"
                bgcolor="#FFFFFF"
                width="$width"
                height="$height"
                name="open-flash-chart"
                align="middle"
                allowScriptAccess="sameDomain"
                type="application/x-shockwave-flash"
                pluginspage="http://www.macromedia.com/go/getflashplayer"
            />
            </object>
        ^;
    }

    return $html;
}


=head1 FUNCTIONS

=head2 smoother_number

round the number up a bit to a nice round number also changes number to an int

=cut

sub smoother_number {
    my $number  = shift;
    my $min_max = shift;
    my $n       = $number;
    
    return
        if not defined $number;

    if ($min_max eq 'max') {
        $n += 1;
    }
    else {
        $n -= 1;
    }
    if ($n <= 10) { $n = int($n) }
    elsif ($n < 30)    { $n = $n + (-$n % 5) }
    elsif ($n < 100)   { $n = $n + (-$n % 10) }
    elsif ($n < 500)   { $n = $n + (-$n % 50) }
    elsif ($n < 1000)  { $n = $n + (-$n % 100) }
    elsif ($n < 10000) { $n = $n + (-$n % 200) }
    else               { $n = $n + (-$n % 500) }
    return int($n);
}


=head2 smooth($axis_name, $axis_type)

Smooth axis min/max.

=cut

sub smooth {
    my $self      = shift;
    my $axis_name = shift;
    my $axis_type = shift;
    
    my $extremes_name = $axis_name.'_'.$axis_type;
    my $cmp_function  = ($axis_type eq 'min' ? \&min : \&max);
    
    my $number;
    foreach my $element (@{$self->elements}) {
        my $element_number = $element->extremes->$extremes_name;
        
        next
            if not defined $element_number;
        $number = $element_number
            if not defined $number;
        $number = $cmp_function->($number, $element_number);
    }
    
    return smoother_number($number, $axis_type);
}

=head2 bg_color()

Same as bg_colour().

=cut

sub bg_color {
    &bg_colour;
}

__PACKAGE__->meta->make_immutable;

1;


__END__

=head1 NOTE

Refresh button will not cause the data file of the graph to be reloaded
so either use proper expiration settings for it or change the name of the
file in html every time you generate new data. Like C<"data.json?".time()>.

=head1 SEE ALSO

L<Chart::OFC>, L<http://teethgrinder.co.uk/open-flash-chart-2/>, L<http://github.com/jozef/chart-ofc2/>

=head1 AUTHOR

Jozef Kutej C<< <jkutej@cpan.org> >>

I've used some of the code from the F<perl-ofc-library/open_flash_chart.pm>
that is shipped together with all the rest OFC2 files.

=head1 CONTRIBUTORS
 
The following people have contributed to the Chart::OFC2 by commiting their
code, sending patches, reporting bugs, asking questions, suggesting useful
advices, nitpicking, chatting on IRC or commenting on my blog (in no particular
order):

    Rodney Webster
    John Goulah C<< <jgoulah@cpan.org> >>
    Noë Snaterse
    Adam J. Foxson C<< <atom@cpan.org> >>
    Jeff Tam

=head1 SUPPORT

=over 4

=item * Mailinglist

L<http://lists.meon.sk/mailman/listinfo/chart-ofc2>

=item * GitHub: issues

L<http://github.com/jozef/chart-ofc2/issues>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Chart-OFC2>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Chart-OFC2>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Chart-OFC2>

=item * Search CPAN

L<http://search.cpan.org/dist/Chart-OFC2>

=back

=head1 COPYRIGHT AND LICENSE

GNU GPL

=cut
