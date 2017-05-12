package Chart::OFC2::HBarValues;

=head1 NAME

Chart::OFC2::HBarValues - OFC2 values for horizontal bar charts object

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

use Moose;
use Moose::Util::TypeConstraints;
use MooseX::StrictConstructor;

use Carp::Clan 'croak';
use List::MoreUtils 'any';

our $VERSION = '0.07';

coerce 'Chart::OFC2::HBarValues'
    => from 'ArrayRef'
    => via { Chart::OFC2::HBarValues->_new_from_arrayref( $_) };

=head1 PROPERTIES

    has 'values' => ( is => 'rw', isa => 'ArrayRef', );

=cut

has 'values'  => ( is => 'rw', isa => 'ArrayRef', 'required' => 1);


=head1 METHODS

=head2 new()

Object constructor.

=head1 _new_from_arrayref

Allow object creation by coerce of ArrayRef.

=cut

sub _new_from_arrayref {
    my $class           = shift;
    my $arrayref_values = shift;
    
    croak 'pass ArrayRef as argument'
        if not ref $arrayref_values ne 'ArrayRef';
    
    my @values;
    foreach my $value (@{$arrayref_values}) {
        if (ref $value eq 'HASH') {
            push @values,  $value;
        }
        else {
            push @values,  { 'right' => $value };
        }
    }
    
    return $class->new(
        'values'  => \@values,
    );
}

=head2 TO_JSON()

Returns ArrayRef that is possible to give to C<encode_json()> function.

NOTE: values are reversed. This is done so that the C<y_axis->labels> match to
the values properly.

=cut

sub TO_JSON {
    my $self = shift;
    
    return [ reverse @{$self->values} ];
}

__PACKAGE__->meta->make_immutable;

1;


__END__

=head1 AUTHOR

Jozef Kutej

=cut
