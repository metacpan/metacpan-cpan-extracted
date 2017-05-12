package Chart::OFC2::Labels;

=head1 NAME

Chart::OFC2::Labels - OFC2 labels object

=head1 SYNOPSIS

    use Chart::OFC2::Labels;
    
    'x_axis' => Chart::OFC2::XAxis->new(
        labels => { 
            labels => [ 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun' ]
        }
    ),

    'x_axis' => Chart::OFC2::XAxis->new(
        labels => {
            labels => [ 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun' ],
            colour => '#555555',
            rotate => 45
        }
    ),

=head1 DESCRIPTION

=cut

use Moose;
use Moose::Util::TypeConstraints;
use MooseX::StrictConstructor;
use MooseX::Aliases;

our $VERSION = '0.07';

=head1 PROPERTIES

    has 'labels' => ( is => 'rw', isa => 'ArrayRef', );
    has 'colour' => ( is => 'rw', isa => 'Str', alias => 'color' );
    has 'rotate' => ( is => 'rw', isa => 'Num', );

=cut

has 'labels' => ( is => 'rw', isa => 'ArrayRef', );
has 'colour' => ( is => 'rw', isa => 'Str', alias => 'color' );
has 'rotate' => ( is => 'rw', isa => 'Num', );


=head1 METHODS

=head2 new()

Object constructor.

=head2 TO_JSON()

Returns HashRef that is possible to give to C<encode_json()> function.

=cut

sub TO_JSON {
    my ($self) = @_;
    
    return {
        map  { my $v = $self->$_; (defined $v ? ($_ => $v) : ()) }
        map  { $_->name } $self->meta->get_all_attributes
    };
}

=head2 color()

Same as colour().

=cut

sub color {
    &colour;
}

__PACKAGE__->meta->make_immutable;

1;


__END__

=head1 AUTHOR

Jozef Kutej

=cut
