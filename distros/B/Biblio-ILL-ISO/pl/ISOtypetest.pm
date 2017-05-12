#!/usr/bin/perl

# Program: ISOtypetest.pm
# Purpose: excersise the types - note that this is not exhaustively testing the modules,
#          just verifying that they do what you would expect.
#

BEGIN{push @INC, "./../lib/"}

use Biblio::ILL::ISO::ILLASNtype;

use Biblio::ILL::ISO::AccountNumber;
use Biblio::ILL::ISO::AlreadyTriedListType;
use Biblio::ILL::ISO::Amount;
use Biblio::ILL::ISO::AmountString;
use Biblio::ILL::ISO::ClientId;
use Biblio::ILL::ISO::CostInfoType;
use Biblio::ILL::ISO::DateTime;
use Biblio::ILL::ISO::DeliveryAddress;
use Biblio::ILL::ISO::DeliveryService;
use Biblio::ILL::ISO::EDeliveryDetails;
use Biblio::ILL::ISO::ElectronicDeliveryService;
use Biblio::ILL::ISO::ElectronicDeliveryServiceSequence;
use Biblio::ILL::ISO::ENUMERATED;
use Biblio::ILL::ISO::ExpiryFlag;
use Biblio::ILL::ISO::Flag;
use Biblio::ILL::ISO::ILLServiceType;
use Biblio::ILL::ISO::ILLServiceTypeSequence;
use Biblio::ILL::ISO::ILLString;
use Biblio::ILL::ISO::ISODate;
use Biblio::ILL::ISO::ISOTime;
use Biblio::ILL::ISO::ItemId;
use Biblio::ILL::ISO::ItemType;
use Biblio::ILL::ISO::MediumType;
use Biblio::ILL::ISO::NameOfPersonOrInstitution;
use Biblio::ILL::ISO::PersonOrInstitutionSymbol;
use Biblio::ILL::ISO::PlaceOnHoldType;
use Biblio::ILL::ISO::PostalAddress;
use Biblio::ILL::ISO::Preference;
use Biblio::ILL::ISO::ProtocolVersionNum;
use Biblio::ILL::ISO::RequesterCHECKEDIN;
use Biblio::ILL::ISO::RequesterOptionalMessageType;
use Biblio::ILL::ISO::RequesterSHIPPED;
use Biblio::ILL::ISO::SearchType;
use Biblio::ILL::ISO::SendToListType;
use Biblio::ILL::ISO::SendToListTypeSequence;
use Biblio::ILL::ISO::SEQUENCE_OF;
use Biblio::ILL::ISO::ServiceDateTime;
use Biblio::ILL::ISO::SupplyMediumInfoType;
use Biblio::ILL::ISO::SupplyMediumInfoTypeSequence;
use Biblio::ILL::ISO::SupplyMediumType;
use Biblio::ILL::ISO::SystemAddress;
use Biblio::ILL::ISO::SystemId;
use Biblio::ILL::ISO::ThirdPartyInfoType;
use Biblio::ILL::ISO::TransactionId;
use Biblio::ILL::ISO::TransactionType;
use Biblio::ILL::ISO::TransportationMode;
# Extensions
use Biblio::ILL::ISO::Extension;
# Answer (new types)
use Biblio::ILL::ISO::ConditionalResults;
use Biblio::ILL::ISO::EstimateResults;
use Biblio::ILL::ISO::HoldPlacedResults;
use Biblio::ILL::ISO::LocationInfo;
use Biblio::ILL::ISO::LocationsResults;
use Biblio::ILL::ISO::ResponderOptionalMessageType;
use Biblio::ILL::ISO::ResponderRECEIVED;
use Biblio::ILL::ISO::ResponderRETURNED;
use Biblio::ILL::ISO::ResultsExplanation;
use Biblio::ILL::ISO::RetryResults;
use Biblio::ILL::ISO::TransactionResults;
use Biblio::ILL::ISO::UnfilledResults;
use Biblio::ILL::ISO::WillSupplyResults;

# Forward-Notification (new types)
#  -- none

# Shipped (new types)
use Biblio::ILL::ISO::DateDue;
use Biblio::ILL::ISO::ShippedConditions;
use Biblio::ILL::ISO::ShippedServiceType;
use Biblio::ILL::ISO::ShippedVia;
use Biblio::ILL::ISO::SupplyDetails;
use Biblio::ILL::ISO::UnitsPerMediumType;

# Conditional-Reply (new types)
#  -- none

# Cancel (new types)
#  -- none

# Cancel-Reply (new types)
#  -- none

# Received (new types)
# External, so not defined:
#   use Biblio::ILL::ISO::SupplementalItemDescription;

# Recall (new types)
#  -- none

# Returned (new types)
#  -- none

# Checked-In (new types)
#  -- none

# Overdue (new types)
#  -- none

# Renew (new types)
#  -- none

# Renew-Answer (new types)
#  -- none

# Lost (new types)
#  -- none

# Damaged (new types)
# Currently unsupported:
#   use Biblio::ILL::ISO::DamagedDetails;

# Message (new types)
#  -- none

# Status-Query (new types)
#  -- none

# Status-Or-Error-Report (new types)
use Biblio::ILL::ISO::ReasonNoReport;
use Biblio::ILL::ISO::MostRecentService;
use Biblio::ILL::ISO::CurrentState;
use Biblio::ILL::ISO::HistoryReport;
use Biblio::ILL::ISO::StatusReport;
use Biblio::ILL::ISO::ErrorReport;
use Biblio::ILL::ISO::ReportSource;
use Biblio::ILL::ISO::AlreadyForwarded;
use Biblio::ILL::ISO::IntermediaryProblem;
use Biblio::ILL::ISO::SecurityProblem;
use Biblio::ILL::ISO::UnableToPerform;
use Biblio::ILL::ISO::UserErrorReport;
use Biblio::ILL::ISO::GeneralProblem;
use Biblio::ILL::ISO::TransactionIdProblem;
use Biblio::ILL::ISO::ILLAPDUtype;
use Biblio::ILL::ISO::StateTransitionProhibited;
use Biblio::ILL::ISO::ProviderErrorReport;

# Expired (new types)
#  -- none


my %hsh = ();
my $obj;
my $obj2;

$hsh{"01.ILLString"} = new Biblio::ILL::ISO::ILLString("A string");
$hsh{"02.AccountNumber"} = new Biblio::ILL::ISO::AccountNumber("1234567890");
$hsh{"03.PersonOrInstitutionSymbol"} = new Biblio::ILL::ISO::PersonOrInstitutionSymbol("MWPL");
$hsh{"04.NameOfPersonOrInstitution"} = new Biblio::ILL::ISO::NameOfPersonOrInstitution("Manitoba Public Library Services");

$hsh{"05.SystemId"} = new Biblio::ILL::ISO::SystemId();
$hsh{"05.SystemId"}->set_person_name("David A. Christensen");
$hsh{"05.SystemId"}->set_institution_symbol("MWPL");

$hsh{"06.AlreadyTriedListType"} = new Biblio::ILL::ISO::AlreadyTriedListType( new Biblio::ILL::ISO::SystemId("BVAS") );
$obj = new Biblio::ILL::ISO::SystemId();
$obj->set_institution_name("Winnipeg Public Library");
$hsh{"06.AlreadyTriedListType"}->add($obj);
$obj = new Biblio::ILL::ISO::SystemId();
$obj->set_person_name("Frank Emil Urwald");
$hsh{"06.AlreadyTriedListType"}->add($obj);
$hsh{"06.AlreadyTriedListType"}->add( new Biblio::ILL::ISO::SystemId("MBOM"));

$hsh{"07.AmountString"} = new Biblio::ILL::ISO::AmountString("\$123.45");
$hsh{"08.Amount"} = new Biblio::ILL::ISO::Amount("\$67.89","CAD");
$hsh{"09.ClientId"} = new Biblio::ILL::ISO::ClientId("David Christensen","Most excellent","007");

$hsh{"10.CostInfoType"} = new Biblio::ILL::ISO::CostInfoType("","","","PLS001","\$40.00");
$hsh{"11.PostalAddress"} = new Biblio::ILL::ISO::PostalAddress("Manitoba Public Library Services",
					  "",
					  "Unit 200",
					  "1525 First Street South",
					  "",
					  "Brandon",
					  "MB",
					  "CANADA",
					  "R7A 7A1"
					  );
$hsh{"12.SystemAddress"} = new Biblio::ILL::ISO::SystemAddress("SMTP","DChristensen\@westman.wave.ca");

$hsh{"13.DeliveryAddress"} = new Biblio::ILL::ISO::DeliveryAddress( new Biblio::ILL::ISO::SystemAddress("SMTP","DChristens\@gov.mb.ca"),
					       new Biblio::ILL::ISO::PostalAddress("Manitoba Public Library Services",
								 "",
								 "Unit 200",
								 "1525 First Street South",
								 "",
								 "Brandon",
								 "MB",
								 "CANADA",
								 "R7A 7A1"
								 )
					       );

$obj = new Biblio::ILL::ISO::EDeliveryDetails( new Biblio::ILL::ISO::SystemAddress("SMTP","bob\@hope.com") );
$hsh{"14.ElectronicDeliveryService"} = new Biblio::ILL::ISO::ElectronicDeliveryService($obj);
$hsh{"14.ElectronicDeliveryService"}->set_description("Just a dummy");
$hsh{"14.ElectronicDeliveryService"}->set_name_or_code("MSG ID: 1001");
$hsh{"14.ElectronicDeliveryService"}->set_delivery_time("235959");

$hsh{"15.ILLServiceTypeSequence"} = new Biblio::ILL::ISO::ILLServiceTypeSequence( new Biblio::ILL::ISO::ILLServiceType("loan"),
								new Biblio::ILL::ISO::ILLServiceType("copy-non-returnable")
								);
$hsh{"15.ILLServiceTypeSequence"}->add(new Biblio::ILL::ISO::ILLServiceType("locations"));

$hsh{"16.ItemType"} = new Biblio::ILL::ISO::ItemType("monograph");
$hsh{"17.MediumType"} = new Biblio::ILL::ISO::MediumType("printed");

$hsh{"18.ItemId"} = new Biblio::ILL::ISO::ItemId("My Book","David Christensen","CHR001.1");
$hsh{"18.ItemId"}->set_item_type("monograph");
$hsh{"18.ItemId"}->set_medium_type("printed");
$hsh{"18.ItemId"}->set_pagination("456");
$hsh{"18.ItemId"}->set_publication_date("2003");

$hsh{"19.RequesterOptionalMessageType"} = new Biblio::ILL::ISO::RequesterOptionalMessageType(1,1,"desires","requires");
$hsh{"20.SearchType"} = new Biblio::ILL::ISO::SearchType("no-Expiry","1","","20030720");

$hsh{"21.SendToListTypeSequence"} = new Biblio::ILL::ISO::SendToListTypeSequence( new Biblio::ILL::ISO::SendToListType( new Biblio::ILL::ISO::SystemId("MBOM") ));
$hsh{"21.SendToListTypeSequence"}->add(new Biblio::ILL::ISO::SendToListType( new Biblio::ILL::ISO::SystemId("MWPL"),
							   new Biblio::ILL::ISO::AccountNumber("PLS001"),
							   new Biblio::ILL::ISO::SystemAddress("SMTP","pls\@gov.mb.ca")
							   )
				       );

$hsh{"22.ServiceDateTime"} = new Biblio::ILL::ISO::ServiceDateTime( new Biblio::ILL::ISO::DateTime("20030623") );
$hsh{"23.ServiceDateTime test 2"} = new Biblio::ILL::ISO::ServiceDateTime( new Biblio::ILL::ISO::DateTime("20030623","114400"),
							 new Biblio::ILL::ISO::DateTime("20030623","114015")
							 );

$hsh{"24.SupplyMediumInfoType"} = new Biblio::ILL::ISO::SupplyMediumInfoType("photocopy","legal-size paper");

$hsh{"25.ThirdPartyInfoType"} = new Biblio::ILL::ISO::ThirdPartyInfoType();
$hsh{"26.ThirdPartyInfoType test 2"} = new Biblio::ILL::ISO::ThirdPartyInfoType(1,1,1,1,"ordered",
							      new Biblio::ILL::ISO::SystemAddress("SMTP","David_A_Christensen\@hotmail.com"),
							      $hsh{"21.SendToListTypeSequence"},
							      $hsh{"06.AlreadyTriedListType"}
							      );

$hsh{"27.TransactionId"} = new Biblio::ILL::ISO::TransactionId("PLS","001","", new Biblio::ILL::ISO::SystemId("MWPL"));

$hsh{"28.DeliveryService"} = new Biblio::ILL::ISO::DeliveryService( new Biblio::ILL::ISO::TransportationMode("Canada Post") );
$hsh{"29.DeliveryService test 2"} = new Biblio::ILL::ISO::ElectronicDeliveryServiceSequence( $hsh{"14.ElectronicDeliveryService"});
$obj = new Biblio::ILL::ISO::ElectronicDeliveryService( new Biblio::ILL::ISO::EDeliveryDetails( new Biblio::ILL::ISO::SystemAddress("SMTP","david\@alnitak.cxm")));
$obj->set_description("Another dummy");
$obj->set_name_or_code("MSG ID: 1002");
$obj->set_delivery_time("083000");
$hsh{"29.DeliveryService test 2"}->add( $obj );

# Answer types (those not covered by Request, anyway).

$hsh{"30.TransactionResults"} = new Biblio::ILL::ISO::TransactionResults("will-supply");
$hsh{"31.ConditionalResultsCondition"} = new Biblio::ILL::ISO::ConditionalResultsCondition("library-use-only");

$obj = new Biblio::ILL::ISO::SystemId();
$obj->set_person_name("David A. Christensen");
$obj->set_institution_symbol("MWPL");
$hsh{"32.LocationInfo"} = new Biblio::ILL::ISO::LocationInfo($obj,
							     new Biblio::ILL::ISO::SystemAddress("SMTP","DChristensen\@westman.wave.ca"),
							     new Biblio::ILL::ISO::ILLString("This is a location note.")
							     );

$hsh{"33.LocationInfoSequence"} = new Biblio::ILL::ISO::LocationInfoSequence( $hsh{"32.LocationInfo"} );
$obj = new Biblio::ILL::ISO::SystemId();
$obj->set_institution_name("Brandon Public Library");
$obj2 = new Biblio::ILL::ISO::LocationInfo($obj, new Biblio::ILL::ISO::SystemAddress("SMTP","library\@brandon.mb.ca") );
$hsh{"33.LocationInfoSequence"}->add($obj2);

$hsh{"34.ConditionalResults"} = new Biblio::ILL::ISO::ConditionalResults(new Biblio::ILL::ISO::ConditionalResultsCondition("charges"),
									 new Biblio::ILL::ISO::ISODate("20030727"),
									 $hsh{"33.LocationInfoSequence"},
									 new Biblio::ILL::ISO::DeliveryService( new Biblio::ILL::ISO::TransportationMode("Canada Post") )
									 );


$hsh{"35.RetryResults"} = new Biblio::ILL::ISO::RetryResults(new Biblio::ILL::ISO::ReasonNotAvailable("in-use-on-loan"),
							     new Biblio::ILL::ISO::ISODate("20030731"),
							     $hsh{"33.LocationInfoSequence"}
							     );
$hsh{"36.UnfilledResults"} = new Biblio::ILL::ISO::UnfilledResults(new Biblio::ILL::ISO::ReasonUnfilled("lost"),
								   $hsh{"33.LocationInfoSequence"}
								   );
$hsh{"37.LocationsResults"} = new Biblio::ILL::ISO::LocationsResults(new Biblio::ILL::ISO::ReasonLocsProvided("not-owned"),
								     $hsh{"33.LocationInfoSequence"}
								     );
$hsh{"38.WillSupplyResults"} = new Biblio::ILL::ISO::WillSupplyResults(new Biblio::ILL::ISO::ReasonWillSupply("at-bindery"),
								       new Biblio::ILL::ISO::ISODate("20030729"),
								       $hsh{"11.PostalAddress"},
								       $hsh{"33.LocationInfoSequence"}
								       );
$hsh{"39.HoldPlacedResults"} = new Biblio::ILL::ISO::HoldPlacedResults(new Biblio::ILL::ISO::ISODate("20030730"),
								       new Biblio::ILL::ISO::MediumType("printed"),
								       $hsh{"33.LocationInfoSequence"}
								       );
$hsh{"40.EstimateResults"} = new Biblio::ILL::ISO::EstimateResults(new Biblio::ILL::ISO::ILLString("56.78"),
								   $hsh{"33.LocationInfoSequence"}
								   );

$hsh{"41.ResponderOptionalMessage"} = new Biblio::ILL::ISO::ResponderOptionalMessageType(1,1,"desires","requires");

# Shipped types
$hsh{"42.DateDue"} = new Biblio::ILL::ISO::DateDue("20030813","false");
$hsh{"43.ShippedConditions"} = new Biblio::ILL::ISO::ShippedConditions("client-signature-required");
$hsh{"44.ShippedServiceType"} = new Biblio::ILL::ISO::ShippedServiceType("loan");
$hsh{"45.ShippedVia"} = new Biblio::ILL::ISO::ShippedVia( new Biblio::ILL::ISO::TransportationMode("Canada Post") );
$hsh{"46.UnitsPerMediumType"} = new Biblio::ILL::ISO::UnitsPerMediumType( new Biblio::ILL::ISO::SupplyMediumType("audio-recording"), 3);
$hsh{"47.SupplyDetails"} = new Biblio::ILL::ISO::SupplyDetails("20030813",
							       "20030920",
							       123,
							       "45.67",
							       new Biblio::ILL::ISO::ShippedConditions("no-reproduction"),
							       $hsh{"45.ShippedVia"},
							       new Biblio::ILL::ISO::Amount("50.00"),
							       "50.00",
							       $hsh{"46.UnitsPerMediumType"}
							       );

# Status-Or-Error-Report
$hsh{"48.ReasonNoReport"} = new Biblio::ILL::ISO::ReasonNoReport("permanent");
$hsh{"49.MostRecentService"} = new Biblio::ILL::ISO::MostRecentService("sTATUS-QUERY");
$hsh{"50.CurrentState"} = new Biblio::ILL::ISO::CurrentState("sHIPPED");
$hsh{"51.HistoryReport"} = new Biblio::ILL::ISO::HistoryReport("20030811",
							       "fORWARD",
							       "20030813",
							       $hsh{"05.SystemId"},
							       "20030815",
							       "Anne Author",
							       "A Title",
							       "",
							       "",
							       "loan",
							       $hsh{"30.TransactionResults"},
							       "This is a history report."
							       );
$hsh{"52.StatusReport"} = new Biblio::ILL::ISO::StatusReport($hsh{"51.HistoryReport"},
							     $hsh{"50.CurrentState"}
							     );
$hsh{"53.ProviderErrorReport"} = new Biblio::ILL::ISO::ProviderErrorReport( new Biblio::ILL::ISO::TransactionIdProblem("duplicate-transaction-id") );
$hsh{"54.ErrorReport"} = new Biblio::ILL::ISO::ErrorReport("Some correlation information",
							   "provider",
							   $hsh{"53.ProviderErrorReport"}
							   );
$hsh{"55.AlreadyForwarded"} = new Biblio::ILL::ISO::AlreadyForwarded($hsh{"05.SystemId"},
								     $hsh{"12.SystemAddress"}
								     );
$hsh{"56.IntermediaryProblem"} = new Biblio::ILL::ISO::IntermediaryProblem("cannot-send-onward");
$hsh{"57.SecurityProblem"} = new Biblio::ILL::ISO::SecurityProblem("This is a security problem.");
$hsh{"58.UnableToPerform"} = new Biblio::ILL::ISO::UnableToPerform("resource-limitation");
$hsh{"59.UserErrorReport"} = new Biblio::ILL::ISO::UserErrorReport($hsh{"57.SecurityProblem"});
$hsh{"60.GeneralProblem"} = new Biblio::ILL::ISO::GeneralProblem("protocol-version-not-supported");
$hsh{"61.ILLAPDUtype"} = new Biblio::ILL::ISO::ILLAPDUtype("eXPIRED");
$hsh{"62.StateTransitionProhibited"} = new Biblio::ILL::ISO::StateTransitionProhibited($hsh{"61.ILLAPDUtype"},
										       $hsh{"50.CurrentState"}
										       );


print "\n---------\n";
foreach my $key (sort keys %hsh) {
    print "\n[$key]\n" . $hsh{$key}->as_pretty_string();
}


