#!perl

use strict;
use warnings;

use Test::Most;
use Test::Deep;
use Test::Exception;

use Business::Fixflo::Client;

use_ok( 'Business::Fixflo::Issue' );
isa_ok(
    my $Issue = Business::Fixflo::Issue->new(
		'Id'              => 1,
        'client'          => Business::Fixflo::Client->new(
            username      => 'foo',
            password      => 'bar',
            custom_domain => 'baz',
        ),
    ),
    'Business::Fixflo::Issue'
);

can_ok(
    $Issue,
    qw/
		url
		get
		to_hash
		to_json
		report

        AdditionalDetails
        AppointmentDate
        BlockName
		CallbackId
        AttendenceDate
        CloseReason
        CostCode
        Quotes
        QuoteEndTime
        QuoteRequests
		FaultTitle
		TermsAccepted
		TenantNotes
		Address
		Id
		InvoiceRecipient
        IsCommunal
        Job
		Firstname
		EmailAddress
        ExternalRefTenancyAgreement
		DirectEmailAddress
		DirectMobileNumber
		TenantId
		TenantPresenceRequested
		TenantAcceptComplete
		Salutation
		Surname
		Title
		Status
		FaultCategory
		Media
		FaultPriority
		Created
		FaultNotes
		ContactNumber
        ContactNumberAlt
		StatusChanged
        Property
        PropertyAddressId
        VulnerableOccupiers
    /,
);

is( $Issue->url,'https://baz.fixflo.com/api/v2/Issue/1','url' );

no warnings 'redefine';
*Business::Fixflo::Client::api_get = sub { 'report_data' };

is( $Issue->report,'report_data','report' );

*Business::Fixflo::Client::api_get = sub { {
    Property => {
        'Address' => {
            'AddressLine1' => 'test2',
            'AddressLine2' => 'bar',
            'Country' => undef,
            'County' => undef,
            'PostCode' => '12 345',
            'Town' => 'qux'
        },
        'ExternalPropertyRef' => 'PP43052',
        'Id' => 12840,
        'PropertyAddressId' => 11753
    },
} };
isa_ok( $Issue->property,'Business::Fixflo::Property' );

my $create_issue_url = $Issue->create_url({
    IsVacant   => 0,
    TenantNo   => '123',
    PropertyId => '456',
});

is(
    $create_issue_url,
    'https://baz.fixflo.com/Issue/Create?IsVacant=0&PropertyId=456&TenantNo=123',
    'create_url',
);

my $search_issue_url = $Issue->search_url({
    a => 'b',
    c => 'd',
});

is(
    $search_issue_url,
    'https://baz.fixflo.com/Dashboard/Home/#/Dashboard/IssueSearchForm?a=b&c=d',
    'search_url',
);

done_testing();

# vim: ts=4:sw=4:et
