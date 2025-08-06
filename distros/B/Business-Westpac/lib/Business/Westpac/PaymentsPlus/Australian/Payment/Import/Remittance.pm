package Business::Westpac::PaymentsPlus::Australian::Payment::Import::Remittance;

=head1 NAME

Business::Westpac::PaymentsPlus::Australian::Payment::Import::Remittance

=head1 SYNOPSIS

    use Business::Westpac::PaymentsPlus::Australian::Payment::Import::Remittance;
    my $Remittance = Business::Westpac::PaymentsPlus::Australian::Payment::Import::Remittance->new(
        remittance_delivery_type => 'EMAIL',
        payee_name => 'Payee 01',
        addressee_name => 'Addressee 01',
        street_1 => 'Level 1',
        street_2 => 'Wallsend Plaza',
        city => 'Wallsend',
        state => 'NSW',
        post_code => '2287',
        country => 'AU',
        email => 'test@test.com',
        remittance_layout_code => 1,
        return_to_address_identifier => 1,
        pass_through_data => "Some pass through data",
    );

    my @csv = $Header->to_csv;

=head1 DESCRIPTION

Class for modeling remittance details in the context of Westpac CSV files.

=cut

use feature qw/ signatures /;

use Moose;
use Types::Standard qw/ Enum /;
with 'Business::Westpac::Role::CSV';
no warnings qw/ experimental::signatures /;

use Carp qw/ croak /;
use Business::Westpac::Types qw/
    add_max_string_attribute
/;

=head1 ATTRIBUTES

All attributes are optional, except were stated, and are read only

=over

=item remittance_delivery_type (Enum, required)

One of: POST, POST_RETURN, POST_OS, POST_MULTI, FAX, EMAIL, NONE

=item remittance_layout_code (PositiveInt)

=item payee_name (Str, max 35 chars, required)

=item addressee_name (Str, max 35 chars)

=item street_1 (Str, max 35 chars)

=item street_2 (Str, max 35 chars)

=item street_3 (Str, max 35 chars)

=item city (Str, max 40 chars)

=item state (Str, max 3 chars)

=item post_code (Str, max 9 chars)

=item country (Str, max 2 chars)

=item fax (Str, max 15 chars)

=item email (Str, max 128 chars)

=item return_to_address_identifier (Str, max 1 chars)

=item pass_through_data (Str, max 120 chars)

=back

=cut

sub record_type { 'R' }

has 'remittance_delivery_type' => (
    is  => 'ro',
    isa => Enum[ qw/
        POST
        POST_RETURN
        POST_OS
        POST_MULTI
        FAX
        EMAIL
        NONE
    / ],
    required => 1,
);

has 'remittance_layout_code' => (
    is       => 'ro',
    isa      => 'PositiveInt',
    required => 0,
);

foreach my $str_attr (
    'PayeeName[35]',
) {
    __PACKAGE__->add_max_string_attribute(
        $str_attr,
        is       => 'ro',
        required => 1,
    );
}

foreach my $str_attr (
    'AddresseeName[35]',
    ( map { "Street_" . $_ . "[35]" } 1 .. 3 ),
    'City[40]',
    'State[3]',
    'PostCode[9]',
    'Country[2]',
    'Fax[15]',
    'Email[128]',
    'ReturnToAddressIdentifier[1]',
) {
    __PACKAGE__->add_max_string_attribute(
        $str_attr,
        is       => 'ro',
        required => 0,
    );
}

# Pass through data appears on a distinct "Remittance Pass-through record"
# (RP) however it can only appear after a Remittance record (R), i.e. this
# class. Given the RP line currently *only* contains a single field, the
# pass through data, it seems overkill to have an entire distinct class for
# it. So for now it's just an attribute on *this* class.
__PACKAGE__->add_max_string_attribute(
    'PassThroughData[120]',
    is       => 'ro',
    required => 0,
);

sub BUILD {
    my ( $self ) = @_;

    my $rdt = $self->remittance_delivery_type;
    my $error = "is required when remittance_delivery_type is $rdt";

    if (
        $rdt eq 'POST'
        || $rdt eq 'POST_OS'
        || $rdt eq 'POST_MULTI'
    ) {
        $self->_has_street_1 || croak( "street_1 $error" );
        $self->_has_city || croak( "city $error" );

        length( $self->city ) <= 25 || croak(
            "city is limited to 25 chars for remittance_delivery_type of $rdt"
        );

        unless ( $rdt eq 'POST_OS' ) {
            $self->_has_state || croak( "state $error" );
            $self->_has_post_code || croak( "post_code $error" );
        }
    }

    $rdt eq 'FAX' && !$self->_has_fax && croak( "fax $error" );
    $rdt eq 'EMAIL' && !$self->_has_email && croak( "email $error" );
}

=head1 METHODS

=head2 to_csv

Convert the attributes to CSV line(s):

    my @csv = $Header->to_csv;

If pass_through_data has content then the CSV will contain
multiple lines

=cut

sub to_csv ( $self ) {

    my @csv_str = $self->attributes_to_csv(
        qw/
            record_type
            remittance_delivery_type
            payee_name
            addressee_name
            street_1
            street_2
            street_3
            city
            state
            post_code
            country
            fax
            email
            remittance_layout_code
            return_to_address_identifier
        /
    );

    # add the "Remittance Pass-through record" if present
    if ( $self->_has_pass_through_data ) {
        push( @csv_str, $self->values_to_csv(
            "RP",$self->pass_through_data
        ) );
    }

    return @csv_str;
}

=head1 SEE ALSO

L<Business::Westpac::Types>

=cut

__PACKAGE__->meta->make_immutable;
