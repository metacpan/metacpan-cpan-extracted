package Chart::OFC2::Title;

=head1 NAME

Chart::OFC2::Title - OFC2 title object

=head1 SYNOPSIS

    use Chart::OFC2;
    use Chart::OFC2::Title;
    
    $chart = Chart::OFC2->new(
        'title'  => 'Bar chart test',
    );
    
    $chart = Chart::OFC2->new(
        'title'  => Chart::OFC2::Title->new(
            'text'  => 'Bar chart test',
            'style' => '{font-size:20px; font-family:Verdana; text-align:center;}',
        ),
    );

=head1 DESCRIPTION

=cut

use Moose;
use Moose::Util::TypeConstraints;
use MooseX::StrictConstructor;

our $VERSION = '0.07';

coerce 'Chart::OFC2::Title'
    => from 'Str'
    => via { Chart::OFC2::Title->new('text' => $_) };

=head1 PROPERTIES

    has 'text'  => (is => 'rw', isa => 'Str', );
    has 'style' => (is => 'rw', isa => 'Str', );

=cut

has 'text'  => (is => 'rw', isa => 'Str', );
has 'style' => (is => 'rw', isa => 'Str', );


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
