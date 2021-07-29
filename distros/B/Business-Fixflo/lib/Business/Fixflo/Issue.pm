package Business::Fixflo::Issue;

=head1 NAME

Business::Fixflo::Issue

=head1 DESCRIPTION

A class for a fixflo issue, extends L<Business::Fixflo::Resource>

=cut

use strict;
use warnings;

use Moo;

extends 'Business::Fixflo::Resource';
with 'Business::Fixflo::Utils';

use Business::Fixflo::Property;

=head1 ATTRIBUTES

    Address
    AdditionalDetails
    AgencyId
    AppointmentDate
    AttendenceDate
    AssignedAgent
    Block
    BlockName
    CallbackId
    CloseReason
    ContactNumber
    ContactNumberAlt
    CostCode
    Created
    DirectEmailAddress
    DirectMobileNumber
    EmailAddress
    ExternalPropertyRef
    ExternalRefTenancyAgreement
    FaultCategory
    FaultNotes
    FaultPriority
    FaultTitle
    FaultTree
    Firstname
    Id
    InvoiceRecipient
    IsCommunal
    Landlord
    Media
    Property
    PropertyId
    PropertyAddressId
    Quotes
    QuoteEndTime
    QuoteNotes
    QuoteRequests
    Salutation
    SearchStatus
    Status
    StatusChanged
    Surname
    TenantAcceptComplete
    TenantId
    TenantNotes
    TenantPresenceRequested
    TermsAccepted
    Title
    WorksAuthorisationLimit
    VulnerableOccupiers

=cut

has [ qw/
    Address
    AdditionalDetails
    AgencyId
    AppointmentDate
    AttendenceDate
    AssignedAgent
    Block
    BlockName
    CallbackId
    ContactNumber
    ContactNumberAlt
    CostCode
    Created
    CloseReason
    DirectEmailAddress
    DirectMobileNumber
    EmailAddress
    ExternalRefTenancyAgreement
    FaultCategory
    FaultId
    FaultNotes
    FaultPriority
    FaultTitle
    FaultTree
    Firstname
    Id
    InvoiceRecipient
    IsCommunal
    Job
    Landlord
    Media
    Property
    PropertyAddressId
    Quotes
    QuoteEndTime
    QuoteNotes
    QuoteRequests
    Salutation
    SearchStatus
    Status
    StatusChanged
    Surname
    TenantAcceptComplete
    TenantId
    TenantNotes
    TenantPresenceRequested
    TermsAccepted
    Title
    WorksAuthorisationLimit
    VulnerableOccupiers
/ ] => (
    is => 'rw',
);

=head1 Operations on an issue

=head2 report

Returns the report content (binary, pdf)

    my $pdf_report = $issue->report;

=cut

sub report {
    my ( $self ) = @_;
    return $self->client->api_get( join( '/',$self->url,'Report' ) );
}

=head2 property

Returns the L<Business::Fixflo::Property> associated with the issue

    my $Property = $issue->property;

=cut

sub property {
    my ( $self ) = @_;

    $self->get if ! $self->Property;

    if ( my $property = $self->Property ) {
        return Business::Fixflo::Property->new(
            client => $self->client,
            %{ $property },
        );
    }

    return undef;
}

=head2 create_url

    my $issue_create_url = $issue->create_url( $params );

Returns a URL string that can be used to create an Issue in Fixflo - the method
can accept a hashref of params that can pre-populate fields on the page:

    IsVacant   => bool,
    TenantNo   => string,
    BMBlockId  => $id,
    PropertyId => $id

Having called the method redirect the user to the returned URL

=cut

sub create_url {
    my ( $self,$params ) = @_;

    my $base_url = join( '/',$self->client->base_url,'Issue','Create' );
    return $base_url . '?' . $self->normalize_params( $params );
}

=head2 search_url

    my $issue_search_url = $issue->search_url( $params );

Much like create_url but returns a URL string for searching. Note this method
can accept many URL parameters so check the Fixflo documentation for a complete
list

Having called the method redirect the user to the returned URL

=cut

sub search_url {
    my ( $self,$params ) = @_;

    my $base_url = join( '/',$self->client->base_url,
        'Dashboard','Home','#','Dashboard','IssueSearchForm',
    );

    return $base_url . '?' . $self->normalize_params( $params );
}

1;

# vim: ts=4:sw=4:et
