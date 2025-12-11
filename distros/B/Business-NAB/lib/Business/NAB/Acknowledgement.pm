package Business::NAB::Acknowledgement;
$Business::NAB::Acknowledgement::VERSION = '0.02';
=head1 NAME

Business::NAB::Acknowledgement

=head1 SYNOPSIS

    my $Ack = $class->new_from_xml(
        $path_to_xml_file, # or an XML string
    );

    my $dom = $Ack->dom; # access to XML::LibXML::Document
    my $DateTime = $Ack->date;

    if ( $Ack->is_accepted ) {
        ...
    }

=head1 DESCRIPTION

Class for parsing NAB file acknowledgements, which are XML files using
some long-forgotten schema from Oracle from the late 1990s. There is no XSD
or DTD...

The various elements are described in section 4 of the NAB "Australian Direct
Entry Payments and Dishonour Report".

=cut

use strict;
use warnings;
use feature qw/ signatures /;
use autodie qw/ :all /;
use Carp    qw/ croak /;
use XML::LibXML;

use Moose;
with 'Business::NAB::Role::AttributeContainer';
extends 'Business::NAB::FileContainer';

use Moose::Util::TypeConstraints;
no warnings qw/ experimental::signatures /;

use Business::NAB::Types;

=head1 ATTRIBUTES

=over

=item dom (XML::LibXML::Document)

The resulting object from parsing the XML, should you want to do
anything more bespoke with it

=item date (NAB::Type::Date, required)

DateTime the acknowledgement was generated

=item result (Str, required)

Inferred from the document's root element, usually the C<type>
attribute, which the documentation lists as:

 * info - "Standard Acknowledgement"
 * warn - File not processed, requires intervention (approval)
 * error - File not processed, requires review and resubmission

=item status (Str, required)

The acknowledgement status, inferred from the user_message element
or the root element:

 * accepted
 * processed
 * rejected
 * pending
 * declined

=item customer_id (Str, required)

NAB Direct Link Mailbox ID

=item company_name (Str, required)

Registered NAB Direct Link customer name

=item original_message_id (Str, required)

=item original_filename (Str, required)

Original file name

=item data_type (Str, optional)

=item data_type_description (Str, optional)

=item user_message (Str, optional)

Short description of the current status of the file

=item detailed_message (Str, optional)

Long description of the current status of the file

=item issue (ArrayRef[Business::NAB::Acknowledgement::Issue], optional)

An arrayref of objects that describe the payment processing

=back

=cut

has [ qw/ dom / ] => (
    is       => 'ro',
    isa      => 'XML::LibXML::Document',
    required => 1,
);

has 'date' => (
    is       => 'ro',
    isa      => 'NAB::Type::Date',
    coerce   => 1,
    required => 1,
);

has [
    qw/
        result
        customer_id
        company_name
        original_message_id
        original_filename
        status
        /
] => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has [
    qw/
        data_type
        data_type_description
        user_message
        detailed_message
        /
] => (
    is       => 'ro',
    isa      => 'Str',
    required => 0,
);

__PACKAGE__->load_attributes(
    'Business::NAB::Acknowledgement',
    'Issue',
);

=head1 METHODS

=head2 new_from_xml

Parses the given XML file (or string) and returns a new instance of the
class with the necessary attributes populates:

    my $Ack = Business::NAB::Acknowledgement->new_from_xml( $xml );

=cut

sub new_from_xml ( $class, $file_or_string ) {

    my $source = -f $file_or_string ? 'location' : 'string';
    my $dom    = XML::LibXML->load_xml(
        $source => $file_or_string,
    );

    my %attributes;

    if ( my ( $Node ) = $dom->findnodes( '//MessageAcknowledgement' ) ) {

        # message ack type
        %attributes = _parse_message_ack( $Node );

    } elsif ( ( $Node ) = $dom->findnodes( '//PaymentsAcknowledgement' ) ) {

        # payments ack type
        %attributes = _parse_payments_ack( $Node );

    } else {
        croak(
            "Unknown acknowledgement type: "
                . $dom->documentElement->nodeName
        );
    }

    return $class->new(
        dom => $dom,
        %attributes,
    );
}

=head2 is_accepted

=head2 is_processed

=head2 is_pending

=head2 is_rejected

=head2 is_declined

=head2 is_received

=head2 is_held

Boolean checks on the acknowledgement:

    if ( $Ack->is_accepted ) {
        ...
    }

=cut

sub is_accepted ( $self ) {
    return $self->_is_status( 'accepted' )
        || $self->_is_status( 'success' );
}

sub is_processed ( $self ) { return $self->_is_status( 'processed' ) }
sub is_pending   ( $self ) { return $self->_is_status( 'pending' ) }
sub is_rejected  ( $self ) { return $self->_is_status( 'rejected' ) }
sub is_held      ( $self ) { return $self->_is_status( 'held' ) }
sub is_declined  ( $self ) { return $self->_is_status( 'declined' ) }
sub is_received  ( $self ) { return $self->_is_status( 'received' ) }

sub _is_status ( $self, $status ) {
    return $self->status eq $status
        ? 1
        : $self->result =~ /$status/i ? 1 : 0;
}

sub _parse_message_ack ( $Node ) {

    my %attributes = _parse_common_ack( $Node );

    $attributes{ status } = lc( $Node->getAttribute( 'type' ) );

    if ( my ( $Message ) = $Node->findnodes( './MessageDetails' ) ) {

        $attributes{ original_message_id }
            = $Message->findvalue( './OriginalMessageId' );
        $attributes{ original_filename }
            = $Message->findvalue( './OriginalFilename' );

        $attributes{ data_type } = $Message->findvalue( './Datatype' );
        $attributes{ data_type_description }
            = $Message->findvalue( './DatatypeDescription' );

        $attributes{ data_type_description } =~ s/\s+$//;
    }

    return %attributes;
}

sub _parse_payments_ack ( $Node ) {

    my %attributes = _parse_common_ack( $Node );

    $attributes{ original_message_id }
        = $Node->findvalue( './OriginalMessageId' );
    $attributes{ original_filename }
        = $Node->findvalue( './OriginalFilename' );

    $attributes{ user_message } = $Node->findvalue( './UserMessage' );

    ( $attributes{ status } ) = (
        $attributes{ user_message }
            =~ /(ACCEPTED|PROCESSED|REJECTED|PENDING|DECLINED|SUCCESS|HELD)/i
    );

    $attributes{ status } = lc( $attributes{ status } );

    $attributes{ detailed_message }
        = $Node->findvalue( './DetailedMessage' );

    return %attributes;
}

sub _parse_common_ack ( $Node ) {

    my %attributes;

    $attributes{ result } = $Node->getAttribute( 'type' );
    $attributes{ issue }  = [];

    $attributes{ date }         = $Node->findvalue( './DateTime' );
    $attributes{ customer_id }  = $Node->findvalue( './CustomerId' );
    $attributes{ company_name } = $Node->findvalue( './CompanyName' );

    foreach my $Issue ( $Node->findnodes( './Issues/Issue' ) ) {

        push(
            @{ $attributes{ issue } },
            {
                code   => $Issue->getAttribute( 'type' ),
                itemId => $Issue->getAttribute( 'itemId' ),
                detail => $Issue->to_literal,
            },
        );
    }

    return %attributes;
}

=head1 SEE ALSO

L<Business::NAB::Types>

L<Business::NAB::Acknowledgement::Issue>

=cut

__PACKAGE__->meta->make_immutable;
