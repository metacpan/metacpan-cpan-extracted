package Business::NAB::BPAY::Payments;
$Business::NAB::BPAY::Payments::VERSION = '0.02';
=head1 NAME

Business::NAB::BPAY::Payments

=head1 SYNOPSIS

    use Business::NAB::BPAY::Payments;

    my $Payments = Business::NAB::BPAY::Payments->new_from_file(
        "/path/to/bpay/payments/batch/file.bpb",
    );

    # parse
    my $Header = $Payments->header_record->[0];

    foreach my $Payment ( $Payments->detail_record->@* ) {
        ...
    }

    my $Trailer = $Payments->trailer_record->[0];

    # create
    $Payments->to_file(
        "/path/to/bpay/payments/batch/file_output.bpb",
        $separator, # defaults to "\r\n"
    );

=head1 DESCRIPTION

Class for parsing / creating a NAB BPAY batch payments file

=cut;

use strict;
use warnings;
use feature qw/ signatures /;
use autodie qw/ :all /;
use Carp    qw/ croak /;

use Moose;
with 'Business::NAB::Role::AttributeContainer';
extends 'Business::NAB::FileContainer';

use Moose::Util::TypeConstraints;
no warnings qw/ experimental::signatures /;

use List::Util qw/ sum0 /;
use Business::NAB::BPAY::Payments::TrailerRecord;

# we have long namespaces and use them multiple times so have
# normalised them out into the $parent and @subclasses below
my $parent = 'Business::NAB::BPAY::Payments';

my @subclasses = (
    qw/
        HeaderRecord
        DetailRecord
        TrailerRecord
        /
);

=head1 ATTRIBUTES

All attributes are ArrayRef[Obj] where Obj are of the Business::NAB::BPAY*
namespace:

    HeaderRecord
    DetailRecord
    TrailerRecord

Convenience methods are available for trivial addition of new elements
to the arrays:

    $Payments->add_header_record( $HeaderRecord );
    $Payments->add_detail_record( $DetailRecord );
    $Payments->add_trailer_record( $TrailerRecord );

=over

=item header_record (ArrayRef[Obj])

=item detail_record (ArrayRef[Obj])

=item trailer_record (ArrayRef[Obj])

=back

=cut

__PACKAGE__->load_attributes( $parent, @subclasses );

=head1 METHODS

=head2 new_from_file

Returns a new instance of the class with attributes populated from
the result of parsing the passed file

    my $Payments = Business::NAB::BPAY::Payments
        ->new_from_file( $file_path );

=cut

sub new_from_file (
    $class,
    $file,
    $class_parent = $parent,    # undocumented as called by subclasses
) {

    my %sub_class_map = (
        1 => 'HeaderRecord',
        2 => 'DetailRecord',
        9 => 'TrailerRecord',
    );

    my $self = ref( $class ) ? $class : $class->new;

    return $self->SUPER::new_from_file(
        $class_parent, $file, \%sub_class_map
    );
}

=head2 to_file

Writes the file content to the passed file path:

    $Payments->to_file(
        $file_path,
        $separator, # defaults to "\r\n"
    );

=cut

sub to_file (
    $self,
    $file,
    $sep = "\r\n",
) {
    open( my $fh, '>', $file );

    print $fh $self->header_record->[ 0 ]->to_record . $sep;
    print $fh $_->to_record . $sep foreach $self->detail_record->@*;

    if ( my $TrailerRecord = $self->trailer_record->[ 0 ] ) {
        print $fh $TrailerRecord->to_record . $sep;
    } else {
        my $total_value = sum0 map { $_->amount }
            $self->detail_record->@*;

        my $TrailerRecord = Business::NAB::BPAY::Payments::TrailerRecord->new(
            total_value_of_payments  => $total_value,
            total_number_of_payments => scalar( $self->detail_record->@* ),
        );

        print $fh $TrailerRecord->to_record . $sep;
    }

    close( $fh );

    return 1;
}

=head1 SEE ALSO

L<Business::NAB::Types>

L<Business::NAB::BPAY::Payments::HeaderRecord>

L<Business::NAB::BPAY::Payments::DetailRecord>

L<Business::NAB::BPAY::Payments::TrailerRecord>

=cut

__PACKAGE__->meta->make_immutable;
