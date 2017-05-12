package Chart::OFC2::ToolTip;

=head1 NAME

Chart::OFC2::ToolTip - OFC2 tool tip settings object

=head1 SYNOPSIS

    use Chart::OFC2;
    use Chart::OFC2::Tooltip;
    
    my $tooltip = Chart::OFC2::ToolTip->new(
        'mouse'      => 2,
        'shadow'     => 0,
        'stroke'     => 5,
        'colour'     => '#6E604F',
        'background' => '#BDB396',
        'title'      => '{font-size: 14px; color: #CC2A43;}',
        'body'       => '{font-size: 10px; font-weight: bold; color: #000000;}',
    );

=head1 DESCRIPTION

OFC2 tooltip settings.

=cut

use Moose;
use Moose::Util::TypeConstraints;
use MooseX::StrictConstructor;

our $VERSION = '0.07';

coerce 'Chart::OFC2::ToolTip'
    => from 'HashRef'
    => via { Chart::OFC2::ToolTip->new($_) };

=head1 PROPERTIES

    has 'mouse'      => (is => 'rw', isa => 'Int',);
    has 'shadow'     => (is => 'rw', isa => 'Bool', );
    has 'stroke'     => (is => 'rw', isa => 'Int',);
    has 'colour'     => (is => 'rw', isa => 'Str',);
    has 'background' => (is => 'rw', isa => 'Str',);
    has 'title'      => (is => 'rw', isa => 'Str',);
    has 'body'       => (is => 'rw', isa => 'Str',);

=cut

has 'mouse'      => (is => 'rw', isa => 'Int',);
has 'shadow'     => (is => 'rw', isa => 'Bool', );
has 'stroke'     => (is => 'rw', isa => 'Int',);
has 'colour'     => (is => 'rw', isa => 'Str',);
has 'background' => (is => 'rw', isa => 'Str',);
has 'title'      => (is => 'rw', isa => 'Str',);
has 'body'       => (is => 'rw', isa => 'Str',);

=head1 METHODS

=head2 new()

Object constructor.

=head2 TO_JSON()

Returns HashRef that is possible to give to C<encode_json()> function.

=cut

sub TO_JSON {
    my $self = shift;
    
    return {
        map  { my $v = $self->$_; (defined $v ? ($_ => $v) : ()) }
        map  { $_->name }
        $self->meta->get_all_attributes
    };
}

__PACKAGE__->meta->make_immutable;

1;


__END__

=head1 AUTHOR

Jozef Kutej

=cut
