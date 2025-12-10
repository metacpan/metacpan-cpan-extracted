package Business::NAB::Australian::DirectEntry::Returns::DetailRecord;
$Business::NAB::Australian::DirectEntry::Returns::DetailRecord::VERSION = '0.01';
=head1 NAME

Business::NAB::Australian::DirectEntry::Returns::DetailRecord

=head1 DESCRIPTION

Class for detail record in the "Australian Direct Entry Payments"
returns file. Inherits all logic/attributes from
L<Business::NAB::Australian::DirectEntry::Payments::DetailRecord>.

=cut

use strict;
use warnings;
use feature qw/ signatures /;

use Moose;
extends 'Business::NAB::Australian::DirectEntry::Payments::DetailRecord';
no warnings qw/ experimental::signatures /;

use Business::NAB::Types qw/
    add_max_string_attribute
    /;

sub record_type { 2 }

sub _pack_template {
    return "A1 A7 A9 A1 A2 A10 A32 A18 A7 A9 A16 A2 A6";
}

=head1 ATTRIBUTES

On top of those inherited from L<Business::NAB::Australian::DirectEntry::Payments::DetailRecord>.

=over

=item original_day_of_processing (NAB::Type::PositiveIntOrZero)

=item original_user_id_number (NAB::Type::PositiveIntOrZero)

=item return_code (NAB::Type::PositiveIntOrZero)

=back

=cut

foreach my $str_attr (
    'original_day_of_processing[2]',
    'original_user_id_number[6]',
) {
    __PACKAGE__->add_max_string_attribute(
        $str_attr,
        is       => 'ro',
        required => $str_attr =~ /original/ ? 0 : 1,
    );
}

has [ qw/ return_code / ] => (
    is       => 'ro',
    isa      => 'NAB::Type::PositiveIntOrZero',
    required => 0,
    default  => sub { 0 },
);

=head1 METHODS

=head2 return_code_description

Returns a string describing the return code

    my $return_reason = $DetailRecord->return_code_description;

=cut

sub return_code_description ( $self ) {

    return {
        0 => undef,
        1 => "Invalid BSB number",
        2 => "Payment stopped",
        3 => "Account closed",
        4 => "Customer deceased",
        5 => "No account or incorrect account number",
        6 => "Refer to customer",
        7 => undef,
        8 => "Invalid User ID Number",
        9 => "Technically invalid",
    }->{ $self->return_code };
}

__PACKAGE__->meta->make_immutable;
