package Chart::OFC2::Pie;

=head1 NAME

Chart::OFC2::Pie - OFC2 Pie chart

=head1 SYNOPSIS

    use Chart::OFC2::Pie;
    
    my $pie = Chart::OFC2::Pie->new(
        tip          => '#val# of #total#<br>#percent# of 100%',
    );
    $pie->values([ (1 .. 5) ]);
    $pie->values->labels([qw( IE Firefox Opera Wii Other)]);
    $pie->values->colours([ '#d01f3c', '#356aa0', '#C79810', '#73880A', '#D15600' ]);

    my $pie2 = Chart::OFC2::Pie->new(
        values       => [
            { 'value' => 1, 'label' => 'IE', },
            { 'value' => 2, 'label' => 'Firefox', },
        ],
    );

    my $pie2 = Chart::OFC2::Pie->new(
        values       => [
            { 'value' => 1, 'label' => 'IE',      'colour' => '#d01f3c' },
            { 'value' => 2, 'label' => 'Firefox', 'colour' => '#356aa0' },
            { 'value' => 3, 'label' => 'Opera',   'colour' => '#C79810' },
            { 'value' => 4, 'label' => 'Wii',     'colour' => '#000000' },
            { 'value' => 5, 'label' => 'Other',   'colour' => '#D15600' },
        ],
    );

=head1 DESCRIPTION

    extends 'Chart::OFC2::Element';

=cut

use Moose;
use MooseX::StrictConstructor;

our $VERSION = '0.07';

extends 'Chart::OFC2::Element';

use Chart::OFC2::PieValues;

=head1 PROPERTIES

=cut

has '+type_name'    => (default => 'pie');
has 'label-colour'  => (is => 'rw', isa => 'ArrayRef',);
has 'border'        => (is => 'rw', isa => 'Str',);
has 'animate'       => (is => 'rw', isa => 'Bool',);
has 'start-angle'   => (is => 'rw', isa => 'Int',);
has 'gradient-fill' => (is => 'rw', isa => 'Bool',);
has 'values'        => (is => 'rw', isa => 'Chart::OFC2::PieValues', 'coerce' => 1,);

override 'TO_JSON' => sub {
    my $self = shift;
    
    my $pie_element = super();
    
    # get the colours from values attribute if defined
    # if one of the colour is undef set to #aaaaaa (OFC2 will not show the graph otherwise)
    $pie_element->{'colours'} = [ map { defined $_ ? $_ : '#aaaaaa' } @{$self->values->colours} ]
        if (defined $self->values->colours);
    
    return $pie_element;
};

1;


__END__

=head1 AUTHOR

Jozef Kutej

=cut
