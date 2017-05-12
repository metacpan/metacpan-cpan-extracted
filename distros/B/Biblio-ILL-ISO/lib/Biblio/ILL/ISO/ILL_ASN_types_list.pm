package Biblio::ILL::ISO::ILL_ASN_types_list;

our $VERSION = '0.03';
#---------------------------------------------------------------------------
# Mods
# 0.03 - 2003.08.13 - added extension handling (currently broken!)
#                   - added Forward-Notification (new types)
#                   - added Shipped (new types)
#                   - added Conditional-Reply (new types)
#                   - added Cancel (new types)
#                   - added Cancel-Reply (new types)
#                   - added Received (new types)
#                   - added Recall (new types)
#                   - added Returned (new types)
#                   - added Checked-In (new types)
#                   - added Overdue (new types)
#                   - added Renew (new types)
#                   - added Renew-Answer (new types)
#                   - added Lost (new types)
#                   - added Damaged (new types)
#                   - added Message (new types)
#                   - added Status-Query (new types)
#                   - added Status-Or-Error-Report (new types)
#                   - added Expired (new types)
# 0.02 - 2003.07.26 - added Answer types
# 0.01 - 2003.07.15 - original version (Request types)
#---------------------------------------------------------------------------

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
use Biblio::ILL::ISO::UnitsPerMediumTypeSequence;

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

1;
