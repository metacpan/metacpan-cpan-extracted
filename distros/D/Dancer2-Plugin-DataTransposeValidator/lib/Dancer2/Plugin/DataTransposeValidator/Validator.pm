package Dancer2::Plugin::DataTransposeValidator::Validator;

use Moo;
use Dancer2::Core::Types qw(Bool Dict Enum HashRef InstanceOf Maybe Str);
use Data::Transpose::Validator;
use namespace::clean;

=head1 NAME

Dancer2::Plugin::DataTransposeValidator::Validator

=head1 VERSION

Version 0.201

=cut

our $VERSION = '0.201';

=head1 CONSTRUCTOR ARGS

The following constructor args are all required.

=head2 params

A hash reference of parameters to be validated.

=cut

has params => (
    is       => 'ro',
    isa      => HashRef,
    required => 1,
);

=head2 rules

A hash reference with the following keys to be used by
L<Data::Transpose::Validator>:

=over

=item * options

The L<Data::Transpose::Validator> constructor arguments.

=item * prepare

The arguments for L<Data::Transpose::Validator/prepare>.

=back

=cut

has rules => (
    is       => 'ro',
    isa      => Dict [ options => HashRef, prepare => HashRef ],
    required => 1,
);

=head2 css_error_class

The css error class. See
L<Dancer2::Plugin::DataTransposeValidator/css_error_class>.

=cut

has css_error_class => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

=head2 errors_hash

Configuration which determines how L</errors> are returned. See
L<Dancer2::Plugin::DataTransposeValidator/errors_hash>.

=cut

has errors_hash => (
    is       => 'ro',
    isa      => Maybe [ Enum [qw/arrayref joined/] ],
    required => 1,
);

=head1 ATTRIBUTES

=cut

has _dtv => (
    is      => 'ro',
    isa     => InstanceOf ['Data::Transpose::Validator'],
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $dtv =
          Data::Transpose::Validator->new( %{ $self->rules->{options} } );
        $dtv->prepare( %{ $self->rules->{prepare} } );
        return $dtv;
    },
);

has _clean => (
    is      => 'ro',
    isa     => Maybe [HashRef],
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->_dtv->transpose( $self->params );
    },
);

=head2 valid

Returns a boolean value indicating whether L</params> are valid.

=cut

has valid => (
    is      => 'ro',
    isa     => Bool,
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->_clean ? 1 : 0;
    },
);

=head2 values

Returns a hash reference of transposed values.

=cut

has values => (
    is      => 'ro',
    isa     => HashRef,
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->valid ? $self->_clean : $self->_dtv->transposed_data;
    },
);

=head2 css

If there are any L</errors>, returns a hash reference of field to css class
for any fields with errors.

=cut

has css => (
    is      => 'ro',
    isa     => HashRef,
    lazy    => 1,
    default => sub {
        my $self = shift;
        return {} if $self->valid;
        my $errors = $self->errors;
        return +{ map { $_ => $self->css_error_class } keys %$errors };
    },
);

=head2 errors

If there are any errors, returns a hash reference of field and errors.

=cut

has errors => (
    is      => 'ro',
    isa     => HashRef,
    lazy    => 1,
    default => sub {
        my $self = shift;
        return {} if $self->valid;

        my $errors_hash = $self->errors_hash || '';
        my $ret;
        my $dtv_errors = $self->_dtv->errors_hash;
        while ( my ( $key, $value ) = each %$dtv_errors ) {
            my @errors = map { $_->{value} } @{$value};
            if ( $errors_hash eq 'joined' ) {
                $ret->{$key} = join( ". ", @errors );
            }
            elsif ( $errors_hash eq 'arrayref' ) {
                $ret->{$key} = \@errors;
            }
            else {
                $ret->{$key} = $errors[0];
            }
        }
        return $ret;
    },
);

# Make sure all attributes are built, for backwards-compat with comsumers
# that expect a hashref rather than an object.
sub BUILD {
    my $self = shift;
    $self->values;
    unless ( $self->valid ) {
        $self->css;
        $self->errors;
    }
}

=head2 TO_JSON

Returns a hash reference of L</valid> and L</values>, and if L</valid> is
false also adds L</css> and L</errors>.

If L<JSON> serializer has C<convert_blesssed> set to a true value, then
this method is called automatically on object before serialization.

=cut

sub TO_JSON {
    my $self = shift;
    return +{
        map { $_ => $self->$_ }
          $self->valid ? (qw/valid values/) : (qw/css errors valid values/)
    };
}

1;
