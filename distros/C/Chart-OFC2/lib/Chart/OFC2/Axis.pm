package Chart::OFC2::Axis;

=head1 NAME

Chart::OFC2::Axis - OFC2 axis base module

=head1 SYNOPSIS

    use Chart::OFC2::Axis;
    my $x_axis = Chart::OFC2::XAxis->new(
        labels => { 
            labels => [ 'Jan', 'Feb', 'Mar', 'Apr', 'May' ] 
        }
    );

=head1 DESCRIPTION

X or Y axis for OFC2.

=cut

use Moose;
use Moose::Util::TypeConstraints;
use MooseX::StrictConstructor;
use MooseX::Aliases;

our $VERSION = '0.07';

use Chart::OFC2;
use Chart::OFC2::Labels;
use Chart::OFC2::Types qw( PositiveInt ChartOFC2Labels );


=head1 PROPERTIES

    has 'name'        => ( is => 'rw', isa => enum(['x_axis', 'y_axis', 'y_axis_right']), required => 1 );
    has 'labels'      => ( is => 'rw', isa => ChartOFC2Labels, coerce  => 1);
    has 'stroke'      => ( is => 'rw', isa => 'Int', );
    has 'colour'      => ( is => 'rw', isa => 'Str', alias => 'color' );
    has 'offset'      => ( is => 'rw', isa => 'Bool', );
    has 'grid_colour' => ( is => 'rw', isa => 'Str', alias => 'grid_color');
    has 'is3d'        => ( is => 'rw', isa => 'Bool', );
    has 'steps'       => ( is => 'rw', isa => PositiveInt, );
    has 'visible'     => ( is => 'rw', isa => 'Bool',  );
    has 'min'         => ( is => 'rw', isa => 'Num|Str|Undef', );   # can be 'a' for auto too
    has 'max'         => ( is => 'rw', isa => 'Num|Str|Undef', );   # can be 'a' for auto too

=cut

coerce 'Chart::OFC2::XAxis'
    => from 'HashRef'
    => via { Chart::OFC2::XAxis->new($_) };
coerce 'Chart::OFC2::YAxis'
    => from 'HashRef'
    => via { Chart::OFC2::YAxis->new($_) };

has 'name'        => ( is => 'rw', isa => enum(['x_axis', 'y_axis', 'y_axis_right']), required => 1 );
has 'labels'      => ( is => 'rw', isa => ChartOFC2Labels, coerce  => 1);
has 'stroke'      => ( is => 'rw', isa => 'Int', );
has 'colour'      => ( is => 'rw', isa => 'Str', alias => 'color' );
has 'offset'      => ( is => 'rw', isa => 'Bool', );
has 'grid_colour' => ( is => 'rw', isa => 'Str', alias => 'grid_color');
has 'is3d'        => ( is => 'rw', isa => 'Bool', );
has 'steps'       => ( is => 'rw', isa => PositiveInt, );
has 'visible'     => ( is => 'rw', isa => 'Bool',  );
has 'min'         => ( is => 'rw', isa => 'Num|Str|Undef', );   # can be 'a' for auto too
has 'max'         => ( is => 'rw', isa => 'Num|Str|Undef', );   # can be 'a' for auto too

=head1 METHODS

=head2 TO_JSON()

Returns HashRef that is possible to give to C<encode_json()> function.

=cut

sub TO_JSON {
    my ($self) = @_;
    
    my %json = (
        map  { my $v = $self->$_; (defined $v ? ($_ => $v) : ()) }
        grep { $_ ne 'name' }
        map  { $_->name } $self->meta->get_all_attributes
    );
    $json{'3d'} = delete $json{'is3d'}
        if (exists $json{'is3d'});

    return \%json;
}

=head2 color()

Same as colour().

=cut

sub color {
    &colour;
}

=head2 grid_color()

Same as grid_colour().

=cut

sub grid_color {
    &grid_colour;
}

__PACKAGE__->meta->make_immutable;

1;


=head1 Chart::OFC2::XAxis

X axis object.

    extends 'Chart::OFC2::Axis';

=cut

package Chart::OFC2::XAxis;
use Moose;
use MooseX::StrictConstructor;

extends 'Chart::OFC2::Axis';

=head1 PROPERTIES

    has '+name'       => ( default => 'x_axis', );
    has 'tick_height' => ( is => 'rw', isa => 'Int', );

=cut

has '+name'       => ( default => 'x_axis', );
has 'tick_height' => ( is => 'rw', isa => 'Int', );

1;


=head1 Chart::OFC2::YAxis

y axis object.

    extends 'Chart::OFC2::Axis';

=cut

package Chart::OFC2::YAxis;
use Moose;
use MooseX::StrictConstructor;

extends 'Chart::OFC2::Axis';

=head1 PROPERTIES

    has '+name'        => ( default => 'y_axis' );
    has 'tick_length' => ( is => 'rw', isa => 'Int', );

=cut

has '+name'        => ( default => 'y_axis' );
has 'tick_length' => ( is => 'rw', isa => 'Int', );

1;


=head1 Chart::OFC2::YAxisRight

y axis on the right side object.

    extends 'Chart::OFC2::YAxis';

=cut

package Chart::OFC2::YAxisRight;

use Moose;
use MooseX::StrictConstructor;

extends 'Chart::OFC2::YAxis';

=head1 PROPERTIES

    has '+name' => ( default => 'y_axis_right' );

=cut

has '+name' => ( default => 'y_axis_right' );

1;


__END__

=head1 AUTHOR

Jozef Kutej

=cut
