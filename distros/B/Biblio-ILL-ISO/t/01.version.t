
use Test::More tests=>224;

BEGIN {
    use_ok( $_ ) for qw( 
	Biblio::ILL::ISO::asn
	Biblio::ILL::ISO::1_0_10161_13_3
	Biblio::ILL::ISO::AccountNumber
	Biblio::ILL::ISO::AlreadyForwarded
	Biblio::ILL::ISO::AlreadyTriedListType
	Biblio::ILL::ISO::Amount
	Biblio::ILL::ISO::AmountString
	Biblio::ILL::ISO::Answer
	Biblio::ILL::ISO::Cancel
	Biblio::ILL::ISO::CancelReply
	Biblio::ILL::ISO::CheckedIn
	Biblio::ILL::ISO::ClientId
	Biblio::ILL::ISO::ConditionalReply
	Biblio::ILL::ISO::ConditionalResults
	Biblio::ILL::ISO::CostInfoType
	Biblio::ILL::ISO::CurrentState
	Biblio::ILL::ISO::Damaged
	Biblio::ILL::ISO::DateDue
	Biblio::ILL::ISO::DateTime
	Biblio::ILL::ISO::DeliveryAddress
	Biblio::ILL::ISO::DeliveryService
	Biblio::ILL::ISO::EDeliveryDetails
	Biblio::ILL::ISO::ENUMERATED
	Biblio::ILL::ISO::ElectronicDeliveryService
	Biblio::ILL::ISO::ElectronicDeliveryServiceSequence
	Biblio::ILL::ISO::ErrorReport
	Biblio::ILL::ISO::EstimateResults
	Biblio::ILL::ISO::Expired
	Biblio::ILL::ISO::ExpiryFlag
	Biblio::ILL::ISO::Extension
	Biblio::ILL::ISO::Flag
	Biblio::ILL::ISO::ForwardNotification
	Biblio::ILL::ISO::GeneralProblem
	Biblio::ILL::ISO::HistoryReport
	Biblio::ILL::ISO::HoldPlacedResults
	Biblio::ILL::ISO::ILLAPDUtype
	Biblio::ILL::ISO::ILLASNtype
	Biblio::ILL::ISO::ILLServiceType
	Biblio::ILL::ISO::ILLServiceTypeSequence
	Biblio::ILL::ISO::ILLString
	Biblio::ILL::ISO::ILL_ASN_types_list
	Biblio::ILL::ISO::IntermediaryProblem
	Biblio::ILL::ISO::ISO
	Biblio::ILL::ISO::ISODate
	Biblio::ILL::ISO::ISOTime
	Biblio::ILL::ISO::ItemId
	Biblio::ILL::ISO::ItemType
	Biblio::ILL::ISO::LocationInfo
	Biblio::ILL::ISO::LocationInfoSequence
	Biblio::ILL::ISO::LocationsResults
	Biblio::ILL::ISO::Lost
	Biblio::ILL::ISO::MediumType
	Biblio::ILL::ISO::Message
	Biblio::ILL::ISO::MostRecentService
	Biblio::ILL::ISO::NameOfPersonOrInstitution
	Biblio::ILL::ISO::Overdue
	Biblio::ILL::ISO::PersonOrInstitutionSymbol
	Biblio::ILL::ISO::PlaceOnHoldType
	Biblio::ILL::ISO::PostalAddress
	Biblio::ILL::ISO::Preference
	Biblio::ILL::ISO::ProtocolVersionNum
	Biblio::ILL::ISO::ProviderErrorReport
	Biblio::ILL::ISO::ReasonLocsProvided
	Biblio::ILL::ISO::ReasonNoReport
	Biblio::ILL::ISO::ReasonNotAvailable
	Biblio::ILL::ISO::ReasonUnfilled
	Biblio::ILL::ISO::ReasonWillSupply
	Biblio::ILL::ISO::Recall
	Biblio::ILL::ISO::Received
	Biblio::ILL::ISO::Renew
	Biblio::ILL::ISO::RenewAnswer
	Biblio::ILL::ISO::ReportSource
	Biblio::ILL::ISO::Request
	Biblio::ILL::ISO::RequesterCHECKEDIN
	Biblio::ILL::ISO::RequesterOptionalMessageType
	Biblio::ILL::ISO::RequesterSHIPPED
	Biblio::ILL::ISO::ResponderOptionalMessageType
	Biblio::ILL::ISO::ResponderRECEIVED
	Biblio::ILL::ISO::ResponderRETURNED
	Biblio::ILL::ISO::ResultsExplanation
	Biblio::ILL::ISO::Returned
	Biblio::ILL::ISO::RetryResults
	Biblio::ILL::ISO::SEQUENCE_OF
	Biblio::ILL::ISO::SearchType
	Biblio::ILL::ISO::SecurityProblem
	Biblio::ILL::ISO::SendToListType
	Biblio::ILL::ISO::SendToListTypeSequence
	Biblio::ILL::ISO::ServiceDateTime
	Biblio::ILL::ISO::Shipped
	Biblio::ILL::ISO::ShippedConditions
	Biblio::ILL::ISO::ShippedVia
	Biblio::ILL::ISO::StateTransitionProhibited
	Biblio::ILL::ISO::StatusOrErrorReport
	Biblio::ILL::ISO::StatusQuery
	Biblio::ILL::ISO::StatusReport
	Biblio::ILL::ISO::SupplyDetails
	Biblio::ILL::ISO::SupplyMediumInfoType
	Biblio::ILL::ISO::SupplyMediumInfoTypeSequence
	Biblio::ILL::ISO::SupplyMediumType
	Biblio::ILL::ISO::SystemAddress
	Biblio::ILL::ISO::SystemId
	Biblio::ILL::ISO::ThirdPartyInfoType
	Biblio::ILL::ISO::TransactionId
	Biblio::ILL::ISO::TransactionIdProblem
	Biblio::ILL::ISO::TransactionResults
	Biblio::ILL::ISO::TransactionType
	Biblio::ILL::ISO::TransportationMode
	Biblio::ILL::ISO::UnableToPerform
	Biblio::ILL::ISO::UnfilledResults
	Biblio::ILL::ISO::UnitsPerMediumType
	Biblio::ILL::ISO::UserErrorReport
	Biblio::ILL::ISO::WillSupplyResults
    );
}

# ASN.1 definitions
is( $Biblio::ILL::ISO::asn::VERSION,	 		'0.03',	'Ok' );
is( $Biblio::ILL::ISO::1_0_10161_13_3::VERSION, 	'0.01',	'Ok' );

# "special" types (base classes)
is( $Biblio::ILL::ISO::ILLASNtype::VERSION, 		'0.01',	'Ok' );
is( $Biblio::ILL::ISO::ENUMERATED::VERSION, 		'0.01',	'Ok' );
is( $Biblio::ILL::ISO::SEQUENCE_OF::VERSION, 		'0.01',	'Ok' );
is( $Biblio::ILL::ISO::ISO::VERSION, 			'0.06',	'Ok' );

# ASN.1 "Application" types (derived from Biblio::ILL::ISO::ISO)
is( $Biblio::ILL::ISO::Answer::VERSION, 		'0.01',	'Ok' );
is( $Biblio::ILL::ISO::Cancel::VERSION, 		'0.02',	'Ok' );
is( $Biblio::ILL::ISO::CancelReply::VERSION, 		'0.01',	'Ok' );
is( $Biblio::ILL::ISO::CheckedIn::VERSION, 		'0.02',	'Ok' );
is( $Biblio::ILL::ISO::ConditionalReply::VERSION,	'0.01',	'Ok' );
is( $Biblio::ILL::ISO::Damaged::VERSION, 		'0.01',	'Ok' );
is( $Biblio::ILL::ISO::Expired::VERSION, 		'0.01',	'Ok' );
is( $Biblio::ILL::ISO::ForwardNotification::VERSION,	'0.01',	'Ok' );
is( $Biblio::ILL::ISO::Lost::VERSION,			'0.02',	'Ok' );
is( $Biblio::ILL::ISO::Message::VERSION, 		'0.01',	'Ok' );
is( $Biblio::ILL::ISO::Overdue::VERSION, 		'0.01',	'Ok' );
is( $Biblio::ILL::ISO::Recall::VERSION, 		'0.01',	'Ok' );
is( $Biblio::ILL::ISO::Received::VERSION, 		'0.02',	'Ok' );
is( $Biblio::ILL::ISO::Renew::VERSION,			'0.01',	'Ok' );
is( $Biblio::ILL::ISO::RenewAnswer::VERSION, 		'0.01',	'Ok' );
is( $Biblio::ILL::ISO::Request::VERSION, 		'0.01',	'Ok' );
is( $Biblio::ILL::ISO::Returned::VERSION, 		'0.02',	'Ok' );
is( $Biblio::ILL::ISO::Shipped::VERSION, 		'0.01',	'Ok' );
is( $Biblio::ILL::ISO::StatusOrErrorReport::VERSION,	'0.01',	'Ok' );
is( $Biblio::ILL::ISO::StatusQuery::VERSION, 		'0.01',	'Ok' );

# things-that-make-"Application"-types (derived from Biblio::ILL::ISO::ILLASNtype)
is( $Biblio::ILL::ISO::AccountNumber::VERSION, 		'0.01',	'Ok' );
is( $Biblio::ILL::ISO::AlreadyForwarded::VERSION,	'0.01',	'Ok' );
is( $Biblio::ILL::ISO::AlreadyTriedListType::VERSION, 	'0.01',	'Ok' );
is( $Biblio::ILL::ISO::Amount::VERSION, 		'0.02',	'Ok' );
is( $Biblio::ILL::ISO::AmountString::VERSION, 		'0.01',	'Ok' );
is( $Biblio::ILL::ISO::ClientId::VERSION, 		'0.01',	'Ok' );
is( $Biblio::ILL::ISO::ConditionalResults::VERSION,	'0.01', 'Ok' );
is( $Biblio::ILL::ISO::CostInfoType::VERSION, 		'0.01',	'Ok' );
is( $Biblio::ILL::ISO::CurrentState::VERSION, 		'0.01',	'Ok' );
is( $Biblio::ILL::ISO::DateDue::VERSION, 		'0.01',	'Ok' );
is( $Biblio::ILL::ISO::DateTime::VERSION, 		'0.01',	'Ok' );
is( $Biblio::ILL::ISO::DeliveryAddress::VERSION, 	'0.01',	'Ok' );
is( $Biblio::ILL::ISO::DeliveryService::VERSION, 	'0.02',	'Ok' );
is( $Biblio::ILL::ISO::EDeliveryDetails::VERSION, 	'0.01',	'Ok' );
is( $Biblio::ILL::ISO::ElectronicDeliveryService::VERSION, '0.01',	'Ok' );
is( $Biblio::ILL::ISO::ElectronicDeliveryServiceSequence::VERSION, '0.01',	'Ok' );
is( $Biblio::ILL::ISO::ErrorReport::VERSION, 		'0.02',	'Ok' );
is( $Biblio::ILL::ISO::EstimateResults::VERSION,	'0.01', 'Ok' );
is( $Biblio::ILL::ISO::ExpiryFlag::VERSION, 		'0.01',	'Ok' );
is( $Biblio::ILL::ISO::Extension::VERSION, 		'0.01',	'Ok' );
is( $Biblio::ILL::ISO::Flag::VERSION, 			'0.01',	'Ok' );
is( $Biblio::ILL::ISO::GeneralProblem::VERSION,		'0.01',	'Ok' );
is( $Biblio::ILL::ISO::HistoryReport::VERSION, 		'0.02',	'Ok' );
is( $Biblio::ILL::ISO::HoldPlacedResults::VERSION,	'0.01', 'Ok' );
is( $Biblio::ILL::ISO::ILLAPDUtype::VERSION, 		'0.01',	'Ok' );
is( $Biblio::ILL::ISO::ILLServiceType::VERSION, 	'0.01',	'Ok' );
is( $Biblio::ILL::ISO::ILLServiceTypeSequence::VERSION,	'0.01',	'Ok' );
is( $Biblio::ILL::ISO::ILLString::VERSION,		'0.01',	'Ok' );
is( $Biblio::ILL::ISO::ILL_ASN_types_list::VERSION,	'0.03',	'Ok' );
is( $Biblio::ILL::ISO::IntermediaryProblem::VERSION,	'0.01',	'Ok' );
is( $Biblio::ILL::ISO::ISODate::VERSION, 		'0.01',	'Ok' );
is( $Biblio::ILL::ISO::ISOTime::VERSION, 		'0.01',	'Ok' );
is( $Biblio::ILL::ISO::ItemId::VERSION, 		'0.01',	'Ok' );
is( $Biblio::ILL::ISO::ItemType::VERSION, 		'0.01',	'Ok' );
is( $Biblio::ILL::ISO::LocationInfo::VERSION,		'0.01', 'Ok' );
is( $Biblio::ILL::ISO::LocationInfoSequence::VERSION,	'0.01', 'Ok' );
is( $Biblio::ILL::ISO::LocationsResults::VERSION,	'0.01', 'Ok' );
is( $Biblio::ILL::ISO::MediumType::VERSION, 		'0.01',	'Ok' );
is( $Biblio::ILL::ISO::MostRecentService::VERSION, 	'0.01',	'Ok' );
is( $Biblio::ILL::ISO::NameOfPersonOrInstitution::VERSION, '0.01',	'Ok' );
is( $Biblio::ILL::ISO::PersonOrInstitutionSymbol::VERSION, '0.01',	'Ok' );
is( $Biblio::ILL::ISO::PlaceOnHoldType::VERSION, 	'0.01',	'Ok' );
is( $Biblio::ILL::ISO::PostalAddress::VERSION,		'0.01',	'Ok' );
is( $Biblio::ILL::ISO::Preference::VERSION, 		'0.01',	'Ok' );
is( $Biblio::ILL::ISO::ProtocolVersionNum::VERSION, 	'0.01',	'Ok' );
is( $Biblio::ILL::ISO::ProviderErrorReport::VERSION, 	'0.01',	'Ok' );
is( $Biblio::ILL::ISO::ReasonLocsProvided::VERSION,	'0.01',	'Ok' );
is( $Biblio::ILL::ISO::ReasonNoReport::VERSION,		'0.01',	'Ok' );
is( $Biblio::ILL::ISO::ReasonNotAvailable::VERSION,	'0.01',	'Ok' );
is( $Biblio::ILL::ISO::ReasonWillSupply::VERSION,	'0.01',	'Ok' );
is( $Biblio::ILL::ISO::ReportSource::VERSION, 		'0.01',	'Ok' );
is( $Biblio::ILL::ISO::RequesterCHECKEDIN::VERSION, 	'0.01',	'Ok' );
is( $Biblio::ILL::ISO::RequesterOptionalMessageType::VERSION, '0.01',	'Ok' );
is( $Biblio::ILL::ISO::RequesterSHIPPED::VERSION, 	'0.01',	'Ok' );
is( $Biblio::ILL::ISO::ResponderOptionalMessageType::VERSION,	'0.01', 'Ok' );
is( $Biblio::ILL::ISO::ResponderRECEIVED::VERSION,	'0.01', 'Ok' );
is( $Biblio::ILL::ISO::ResponderRETURNED::VERSION,	'0.01', 'Ok' );
is( $Biblio::ILL::ISO::ResultsExplanation::VERSION,	'0.01', 'Ok' );
is( $Biblio::ILL::ISO::RetryResults::VERSION,		'0.01', 'Ok' );
is( $Biblio::ILL::ISO::SearchType::VERSION, 		'0.02',	'Ok' );
is( $Biblio::ILL::ISO::SecurityProblem::VERSION,	'0.01',	'Ok' );
is( $Biblio::ILL::ISO::SendToListType::VERSION, 	'0.01',	'Ok' );
is( $Biblio::ILL::ISO::SendToListTypeSequence::VERSION, '0.01',	'Ok' );
is( $Biblio::ILL::ISO::ServiceDateTime::VERSION, 	'0.01',	'Ok' );
is( $Biblio::ILL::ISO::ShippedConditions::VERSION,	'0.01',	'Ok' );
is( $Biblio::ILL::ISO::ShippedServiceType::VERSION,	'0.01',	'Ok' );
is( $Biblio::ILL::ISO::ShippedVia::VERSION, 		'0.01',	'Ok' );
is( $Biblio::ILL::ISO::StateTransitionProhibited::VERSION, '0.01',	'Ok' );
is( $Biblio::ILL::ISO::StatusReport::VERSION, 		'0.01',	'Ok' );
is( $Biblio::ILL::ISO::SupplyDetails::VERSION, 		'0.01',	'Ok' );
is( $Biblio::ILL::ISO::SupplyMediumInfoType::VERSION, 	'0.01',	'Ok' );
is( $Biblio::ILL::ISO::SupplyMediumInfoTypeSequence::VERSION, '0.02',	'Ok' );
is( $Biblio::ILL::ISO::SupplyMediumType::VERSION, 	'0.01',	'Ok' );
is( $Biblio::ILL::ISO::SystemAddress::VERSION, 		'0.01',	'Ok' );
is( $Biblio::ILL::ISO::SystemId::VERSION, 		'0.01',	'Ok' );
is( $Biblio::ILL::ISO::ThirdPartyInfoType::VERSION, 	'0.01',	'Ok' );
is( $Biblio::ILL::ISO::TransactionId::VERSION, 		'0.01',	'Ok' );
is( $Biblio::ILL::ISO::TransactionIdProblem::VERSION,	'0.01',	'Ok' );
is( $Biblio::ILL::ISO::TransactionResults::VERSION, 	'0.01',	'Ok' );
is( $Biblio::ILL::ISO::TransactionType::VERSION, 	'0.01',	'Ok' );
is( $Biblio::ILL::ISO::TransportationMode::VERSION, 	'0.01',	'Ok' );
is( $Biblio::ILL::ISO::UnableToPerform::VERSION,	'0.01',	'Ok' );
is( $Biblio::ILL::ISO::UnfilledResults::VERSION,	'0.01', 'Ok' );
is( $Biblio::ILL::ISO::UnitsPerMediumType::VERSION,	'0.01',	'Ok' );
is( $Biblio::ILL::ISO::UserErrorReport::VERSION,	'0.01',	'Ok' );
is( $Biblio::ILL::ISO::WillSupplyResults::VERSION,	'0.01', 'Ok' );



