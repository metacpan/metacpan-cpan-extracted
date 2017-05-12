package Business::EDI::DataElement;
use Carp;
use strict;
use warnings;

use UNIVERSAL::require;
use Business::EDI;
use base 'Business::EDI';

use vars qw/ %code_hash /;
our $VERSION = 0.01;

my %codes = ();  # caching
my @fields = qw(code label value desc);

sub bad_names {   # CLASS method
    return grep {exists $codes{$_} and ! $codes{$_}} keys %codes;   # if it's there, and empty/undef, it's bad
}
sub bad_name {
    my $name = shift or return;
    exists $codes{$name} or return 0;       # havne't seen it yet, doesn't mean it's bad
    return defined($codes{$name}) ? 0 : 1;  # but if we've seen it, and it's undef, it's bad.
}
sub clear_cache {
    my $size = scalar keys %codes;
    %codes = ();
    return $size;
}

sub new {       # constructor:
    my $class = shift;
    my $code  = shift or carp "No code argument for DataElement type '$class' specified";
    $code or return;
    my $self = bless({}, $class);
    unless ($self->init($code, @_)) {
        carp "init() failed for code '$code'";
        return;
    }
    return $self;
}

sub init {
    my $self = shift;
    my $code = shift or return;
    my $codes = $self->codehash();
    $codes->{$code} or return;
    $self->{code } = $code;
    $self->{label} = $codes->{$code};
    $self->{value} = shift if scalar @_;
    $self->{desc } = $self->desc($self->{label});
    $self->{_permitted} = {(map {$_ => 1} @fields)};
    return $self;
}

sub get_codelist {
    my $self   = shift;
    my $target = @_ ? shift : $self->label();
    unless ($target) {
        carp "Empty target for get_codelist";
        return;
    }
    if (bad_name($target)) {
        carp "get_codelist already failed on previous attempts for target $target";
        return;
    }
    my $pack = "Business::EDI::CodeList::$target";
    unless ($pack->require()) {
        carp "$pack not found";
        $codes{$target} = undef;
    }
    my $sub = $pack->can('get_codes');
    $codes{$target} = eval { $sub };
    $codes{$target} or carp "$pack failed required get_codes() call";
    return $codes{$target};
}

sub codelist {
    my $self = shift;
    if (@_) {
        my $incoming = shift;
        # if we got an object, we'll treat it as the whole CodeList referent
        $self->{codelist} = ref($incoming) ? $incoming : $self->get_codelist($incoming);
    }
    return $self->{codelist};
}

# sub code  { my $self = shift; @_ and $self->{code } = shift; return $self->{code }; }
# sub label { my $self = shift; @_ and $self->{label} = shift; return $self->{label}; }
# sub value { my $self = shift; @_ and $self->{value} = shift; return $self->{value}; }
sub desc {
    my $self = shift;
    local $_ = @_ ? shift : $self->label();
    my @humps;
    foreach(/([A-Z][a-z]+)/g) {
        push @humps, lc($_);
    }
    return ucfirst join ' ', @humps;
}

# methods in common w/ other EDI objects for recursive functionality
# sub part_keys {return @fields;}

sub codehash {
    my $self = shift;
    unless(%code_hash) {
        %code_hash = (
            1000 => 'DocumentName',                                                   # B
            1001 => 'DocumentNameCode',                                               # C
            1003 => 'MessageTypeCode',                                                # B
            1004 => 'DocumentIdentifier',                                             # C
            1049 => 'MessageSectionCode',                                             # B
            1050 => 'SequencePositionIdentifier',                                     # C
            1052 => 'MessageItemIdentifier',                                          # B
            1054 => 'MessageSubitemIdentifier',                                       # B
            1056 => 'VersionIdentifier',                                              # B
            1058 => 'ReleaseIdentifier',                                              # B
            1060 => 'RevisionIdentifier',                                             # B
            1073 => 'DocumentLineActionCode',                                         # B
            1082 => 'LineItemIdentifier',                                             # C
            1131 => 'CodeListIdentificationCode',                                     # C
            1145 => 'TravellerReferenceIdentifier',                                   # I
            1146 => 'AccountName',                                                    # B
            1147 => 'AccountIdentifier',                                              # B
            1148 => 'AccountAbbreviatedName',                                         # B
            1153 => 'ReferenceCodeQualifier',                                         # C
            1154 => 'ReferenceIdentifier',                                            # C
            1156 => 'DocumentLineIdentifier',                                         # C
            1159 => 'SequenceIdentifierSourceCode',                                   # B
            1170 => 'AccountingJournalName',                                          # B
            1171 => 'AccountingJournalIdentifier',                                    # B
            1218 => 'DocumentOriginalsRequiredQuantity',                              # B
            1220 => 'DocumentCopiesRequiredQuantity',                                 # B
            1222 => 'ConfigurationLevelNumber',                                       # B
            1225 => 'MessageFunctionCode',                                            # C
            1227 => 'CalculationSequenceCode',                                        # B
            1228 => 'ActionDescription',                                              # B
            1229 => 'ActionCode',                                                     # C
            1230 => 'AllowanceOrChargeIdentifier',                                    # B
            1312 => 'ConsignmentLoadSequenceIdentifier',                              # B
            1366 => 'DocumentSourceDescription',                                      # B
            1373 => 'DocumentStatusCode',                                             # B
            1476 => 'ControllingAgencyIdentifier',                                    # B
            1490 => 'ConsolidationItemNumber',                                        # B
            1496 => 'GoodsItemNumber',                                                # B
            1501 => 'ComputerEnvironmentDetailsCodeQualifier',                        # B
            1502 => 'DataFormatDescription',                                          # B
            1503 => 'DataFormatDescriptionCode',                                      # C
            1505 => 'ValueListTypeCode',                                              # B
            1507 => 'DesignatedClassCode',                                            # B
            1508 => 'FileName',                                                       # B
            1510 => 'ComputerEnvironmentName',                                        # B
            1511 => 'ComputerEnvironmentNameCode',                                    # C
            1514 => 'ValueListName',                                                  # B
            1516 => 'FileFormatName',                                                 # B
            1518 => 'ValueListIdentifier',                                            # B
            1520 => 'DataSetIdentifier',                                              # B
            1523 => 'MessageImplementationIdentificationCode',                        # B
            2000 => 'Date',                                                           # I
            2002 => 'Time',                                                           # I
            2005 => 'DateOrTimeOrPeriodFunctionCodeQualifier',                        # C
            2009 => 'TermsTimeRelationCode',                                          # B
            2013 => 'FrequencyCode',                                                  # C
            2015 => 'DespatchPatternCode',                                            # C
            2017 => 'DespatchPatternTimingCode',                                      # C
            2018 => 'Age',                                                            # I
            2023 => 'PeriodTypeCodeQualifier',                                        # B
            2029 => 'TimeZoneIdentifier',                                             # I
            2031 => 'TimeVariationQuantity',                                          # I
            2116 => 'TimeZoneDifferenceQuantity',                                     # I
            2118 => 'PeriodDetailDescription',                                        # B
            2119 => 'PeriodDetailDescriptionCode',                                    # B
            2148 => 'DateVariationNumber',                                            # I
            2151 => 'PeriodTypeCode',                                                 # C
            2152 => 'PeriodCountQuantity',                                            # C
            2155 => 'ChargePeriodTypeCode',                                           # I
            2156 => 'CheckinTime',                                                    # I
            2160 => 'DaysOfWeekSetIdentifier',                                        # I
            2162 => 'JourneyLegDurationQuantity',                                     # I
            2164 => 'MillisecondTime',                                                # I
            2379 => 'DateOrTimeOrPeriodFormatCode',                                   # C
            2380 => 'DateOrTimeOrPeriodText',                                         # C
            2475 => 'EventTimeReferenceCode',                                         # B
            3005 => 'MaintenanceOperationOperatorCode',                               # B
            3009 => 'MaintenanceOperationPayerCode',                                  # B
            3035 => 'PartyFunctionCodeQualifier',                                     # C
            3036 => 'PartyName',                                                      # C
            3039 => 'PartyIdentifier',                                                # C
            3042 => 'StreetAndNumberOrPostOfficeBoxIdentifier',                       # C
            3045 => 'PartyNameFormatCode',                                            # C
            3055 => 'CodeListResponsibleAgencyCode',                                  # C
            3077 => 'TestMediumCode',                                                 # B
            3079 => 'OrganisationClassificationCode',                                 # B
            3082 => 'OrganisationalClassName',                                        # B
            3083 => 'OrganisationalClassNameCode',                                    # B
            3124 => 'NameAndAddressDescription',                                      # C
            3126 => 'CarrierName',                                                    # B
            3127 => 'CarrierIdentifier',                                              # B
            3131 => 'AddressTypeCode',                                                # C
            3139 => 'ContactFunctionCode',                                            # B
            3148 => 'CommunicationAddressIdentifier',                                 # C
            3153 => 'CommunicationMediumTypeCode',                                    # C
            3155 => 'CommunicationMeansTypeCode',                                     # B
            3164 => 'CityName',                                                       # C
            3192 => 'AccountHolderName',                                              # B
            3194 => 'AccountHolderIdentifier',                                        # B
            3197 => 'AgentIdentifier',                                                # I
            3207 => 'CountryIdentifier',                                              # C
            3222 => 'FirstRelatedLocationName',                                       # B
            3223 => 'FirstRelatedLocationIdentifier',                                 # C
            3224 => 'LocationName',                                                   # C
            3225 => 'LocationIdentifier',                                             # C
            3227 => 'LocationFunctionCodeQualifier',                                  # C
            3228 => 'CountrySubdivisionName',                                         # C
            3229 => 'CountrySubdivisionIdentifier',                                   # C
            3232 => 'SecondRelatedLocationName',                                      # B
            3233 => 'SecondRelatedLocationIdentifier',                                # C
            3236 => 'SampleLocationDescription',                                      # B
            3237 => 'SampleLocationDescriptionCode',                                  # B
            3239 => 'CountryOfOriginIdentifier',                                      # B
            3251 => 'PostalIdentificationCode',                                       # C
            3279 => 'GeographicAreaCode',                                             # B
            3285 => 'InstructionReceivingPartyIdentifier',                            # B
            3286 => 'AddressComponentDescription',                                    # C
            3289 => 'PersonCharacteristicCodeQualifier',                              # B
            3292 => 'NationalityName',                                                # B
            3293 => 'NationalityNameCode',                                            # B
            3295 => 'NameOriginalAlphabetCode',                                       # B
            3299 => 'AddressPurposeCode',                                             # C
            3301 => 'EnactingPartyIdentifier',                                        # B
            3310 => 'InheritedCharacteristicDescription',                             # B
            3311 => 'InheritedCharacteristicDescriptionCode',                         # B
            3397 => 'NameStatusCode',                                                 # C
            3398 => 'NameComponentDescription',                                       # B
            3401 => 'NameComponentUsageCode',                                         # B
            3403 => 'NameTypeCode',                                                   # B
            3405 => 'NameComponentTypeCodeQualifier',                                 # B
            3412 => 'ContactName',                                                    # B
            3413 => 'ContactIdentifier',                                              # C
            3432 => 'InstitutionName',                                                # B
            3433 => 'InstitutionNameCode',                                            # B
            3434 => 'InstitutionBranchIdentifier',                                    # B
            3436 => 'InstitutionBranchLocationName',                                  # B
            3446 => 'PartyTaxIdentifier',                                             # B
            3449 => 'BankIdentifier',                                                 # I
            3452 => 'LanguageName',                                                   # C
            3453 => 'LanguageNameCode',                                               # C
            3455 => 'LanguageCodeQualifier',                                          # C
            3457 => 'OriginatorTypeCode',                                             # I
            3459 => 'FrequentTravellerIdentifier',                                    # I
            3460 => 'GivenName',                                                      # I
            3463 => 'GateIdentifier',                                                 # I
            3465 => 'InhouseIdentifier',                                              # I
            3475 => 'AddressStatusCode',                                              # C
            3477 => 'AddressFormatCode',                                              # C
            3478 => 'MaritalStatusDescription',                                       # B
            3479 => 'MaritalStatusDescriptionCode',                                   # C
            3480 => 'PersonJobTitle',                                                 # B
            3482 => 'ReligionName',                                                   # B
            3483 => 'ReligionNameCode',                                               # B
            3493 => 'NationalityCodeQualifier',                                       # B
            3496 => 'SalesChannelIdentifier',                                         # B
            3499 => 'GenderCode',                                                     # C
            3500 => 'FamilyName',                                                     # I
            3503 => 'AccessAuthorisationIdentifier',                                  # I
            3504 => 'GivenNameTitleDescription',                                      # I
            3507 => 'BenefitCoverageConstituentsCode',                                # I
            4009 => 'OptionCode',                                                     # I
            4017 => 'DeliveryPlanCommitmentLevelCode',                                # B
            4018 => 'RelatedInformationDescription',                                  # I
            4022 => 'BusinessDescription',                                            # B
            4025 => 'BusinessFunctionCode',                                           # C
            4027 => 'BusinessFunctionTypeCodeQualifier',                              # B
            4035 => 'PriorityTypeCodeQualifier',                                      # B
            4036 => 'PriorityDescription',                                            # B
            4037 => 'PriorityDescriptionCode',                                        # B
            4038 => 'AdditionalSafetyInformationDescription',                         # B
            4039 => 'AdditionalSafetyInformationDescriptionCode',                     # B
            4043 => 'TradeClassCode',                                                 # B
            4044 => 'SafetySectionName',                                              # B
            4046 => 'SafetySectionNumber',                                            # B
            4048 => 'CertaintyDescription',                                           # C
            4049 => 'CertaintyDescriptionCode',                                       # C
            4051 => 'CharacteristicRelevanceCode',                                    # B
            4052 => 'DeliveryOrTransportTermsDescription',                            # B
            4053 => 'DeliveryOrTransportTermsDescriptionCode',                        # B
            4055 => 'DeliveryOrTransportTermsFunctionCode',                           # B
            4056 => 'QuestionDescription',                                            # B
            4057 => 'QuestionDescriptionCode',                                        # B
            4059 => 'ClauseCodeQualifier',                                            # B
            4065 => 'ContractAndCarriageConditionCode',                               # B
            4068 => 'ClauseName',                                                     # B
            4069 => 'ClauseNameCode',                                                 # B
            4071 => 'ProvisoCodeQualifier',                                           # B
            4072 => 'ProvisoTypeDescription',                                         # B
            4073 => 'ProvisoTypeDescriptionCode',                                     # B
            4074 => 'ProvisoCalculationDescription',                                  # B
            4075 => 'ProvisoCalculationDescriptionCode',                              # B
            4078 => 'HandlingInstructionDescription',                                 # B
            4079 => 'HandlingInstructionDescriptionCode',                             # B
            4183 => 'SpecialConditionCode',                                           # C
            4184 => 'SpecialRequirementDescription',                                  # I
            4187 => 'SpecialRequirementTypeCode',                                     # I
            4215 => 'TransportChargesPaymentMethodCode',                              # B
            4219 => 'TransportServicePriorityCode',                                   # B
            4221 => 'DiscrepancyNatureIdentificationCode',                            # B
            4233 => 'MarkingInstructionsCode',                                        # B
            4237 => 'PaymentArrangementCode',                                         # B
            4276 => 'PaymentTermsDescription',                                        # B
            4277 => 'PaymentTermsDescriptionIdentifier',                              # B
            4279 => 'PaymentTermsTypeCodeQualifier',                                  # B
            4294 => 'ChangeReasonDescription',                                        # B
            4295 => 'ChangeReasonDescriptionCode',                                    # B
            4343 => 'ResponseTypeCode',                                               # C
            4344 => 'ResponseDescription',                                            # B
            4345 => 'ResponseDescriptionCode',                                        # B
            4347 => 'ProductIdentifierCodeQualifier',                                 # B
            4383 => 'BankOperationCode',                                              # B
            4400 => 'InstructionDescription',                                         # B
            4401 => 'InstructionDescriptionCode',                                     # C
            4403 => 'InstructionTypeCodeQualifier',                                   # C
            4404 => 'StatusDescription',                                              # B
            4405 => 'StatusDescriptionCode',                                          # C
            4407 => 'SampleProcessStepCode',                                          # B
            4415 => 'TestMethodIdentifier',                                           # B
            4416 => 'TestDescription',                                                # B
            4419 => 'TestAdministrationMethodCode',                                   # B
            4424 => 'TestReasonName',                                                 # B
            4425 => 'TestReasonNameCode',                                             # B
            4431 => 'PaymentGuaranteeMeansCode',                                      # B
            4435 => 'PaymentChannelCode',                                             # B
            4437 => 'AccountTypeCodeQualifier',                                       # B
            4439 => 'PaymentConditionsCode',                                          # C
            4440 => 'FreeText',                                                       # C
            4441 => 'FreeTextDescriptionCode',                                        # B
            4447 => 'FreeTextFormatCode',                                             # B
            4451 => 'TextSubjectCodeQualifier',                                       # C
            4453 => 'FreeTextFunctionCode',                                           # B
            4455 => 'BackOrderArrangementTypeCode',                                   # B
            4457 => 'SubstitutionConditionCode',                                      # B
            4461 => 'PaymentMeansCode',                                               # B
            4463 => 'IntracompanyPaymentIndicatorCode',                               # B
            4465 => 'AdjustmentReasonDescriptionCode',                                # C
            4467 => 'PaymentMethodCode',                                              # I
            4469 => 'PaymentPurposeCode',                                             # I
            4471 => 'SettlementMeansCode',                                            # B
            4472 => 'InformationType',                                                # B
            4473 => 'InformationTypeCode',                                            # C
            4474 => 'AccountingEntryTypeName',                                        # B
            4475 => 'AccountingEntryTypeNameCode',                                    # B
            4487 => 'FinancialTransactionTypeCode',                                   # B
            4493 => 'DeliveryInstructionCode',                                        # B
            4494 => 'InsuranceCoverDescription',                                      # B
            4495 => 'InsuranceCoverDescriptionCode',                                  # B
            4497 => 'InsuranceCoverTypeCode',                                         # C
            4499 => 'InventoryMovementReasonCode',                                    # B
            4501 => 'InventoryMovementDirectionCode',                                 # B
            4503 => 'InventoryBalanceMethodCode',                                     # B
            4505 => 'CreditCoverRequestTypeCode',                                     # B
            4507 => 'CreditCoverResponseTypeCode',                                    # B
            4509 => 'CreditCoverResponseReasonCode',                                  # B
            4510 => 'RequestedInformationDescription',                                # C
            4511 => 'RequestedInformationDescriptionCode',                            # B
            4513 => 'MaintenanceOperationCode',                                       # C
            4517 => 'SealConditionCode',                                              # B
            4519 => 'DefinitionIdentifier',                                           # B
            4521 => 'PremiumCalculationComponentIdentifier',                          # B
            4522 => 'PremiumCalculationComponentValueCategoryIdentifier',             # B
            4525 => 'SealTypeCode',                                                   # B
            5004 => 'MonetaryAmount',                                                 # C
            5006 => 'MonetaryAmountFunctionDescription',                              # B
            5007 => 'MonetaryAmountFunctionDescriptionCode',                          # B
            5013 => 'IndexCodeQualifier',                                             # B
            5025 => 'MonetaryAmountTypeCodeQualifier',                                # C
            5027 => 'IndexTypeIdentifier',                                            # B
            5030 => 'IndexText',                                                      # C
            5039 => 'IndexRepresentationCode',                                        # B
            5047 => 'ContributionCodeQualifier',                                      # B
            5048 => 'ContributionTypeDescription',                                    # B
            5049 => 'ContributionTypeDescriptionCode',                                # B
            5104 => 'MonetaryAmountFunctionDetailDescription',                        # B
            5105 => 'MonetaryAmountFunctionDetailDescriptionCode',                    # B
            5118 => 'PriceAmount',                                                    # C
            5125 => 'PriceCodeQualifier',                                             # C
            5152 => 'DutyOrTaxOrFeeTypeName',                                         # B
            5153 => 'DutyOrTaxOrFeeTypeNameCode',                                     # C
            5160 => 'TotalMonetaryAmount',                                            # I
            5189 => 'AllowanceOrChargeIdentificationCode',                            # B
            5213 => 'SublineItemPriceChangeOperationCode',                            # C
            5237 => 'ChargeCategoryCode',                                             # B
            5242 => 'RateOrTariffClassDescription',                                   # B
            5243 => 'RateOrTariffClassDescriptionCode',                               # C
            5245 => 'PercentageTypeCodeQualifier',                                    # B
            5249 => 'PercentageBasisIdentificationCode',                              # B
            5261 => 'ChargeUnitCode',                                                 # I
            5263 => 'RateTypeIdentifier',                                             # I
            5267 => 'ServiceTypeCode',                                                # I
            5273 => 'DutyOrTaxOrFeeRateBasisCode',                                    # B
            5275 => 'SupplementaryRateOrTariffCode',                                  # B
            5278 => 'DutyOrTaxOrFeeRate',                                             # C
            5279 => 'DutyOrTaxOrFeeRateCode',                                         # B
            5283 => 'DutyOrTaxOrFeeFunctionCodeQualifier',                            # B
            5284 => 'UnitPriceBasisQuantity',                                         # B
            5286 => 'DutyOrTaxOrFeeAssessmentBasisQuantity',                          # B
            5289 => 'DutyOrTaxOrFeeAccountCode',                                      # B
            5305 => 'DutyOrTaxOrFeeCategoryCode',                                     # B
            5307 => 'TaxOrDutyOrFeePaymentDueDateCode',                               # B
            5314 => 'RemunerationTypeName',                                           # B
            5315 => 'RemunerationTypeNameCode',                                       # B
            5375 => 'PriceTypeCode',                                                  # C
            5377 => 'PriceChangeTypeCode',                                            # I
            5379 => 'ProductGroupTypeCode',                                           # B
            5387 => 'PriceSpecificationCode',                                         # B
            5388 => 'ProductGroupName',                                               # B
            5389 => 'ProductGroupNameCode',                                           # C
            5393 => 'PriceMultiplierTypeCodeQualifier',                               # B
            5394 => 'PriceMultiplierRate',                                            # B
            5402 => 'CurrencyExchangeRate',                                           # C
            5419 => 'RateTypeCodeQualifier',                                          # B
            5420 => 'UnitPriceBasisRate',                                             # B
            5463 => 'AllowanceOrChargeCodeQualifier',                                 # B
            5479 => 'RelationCode',                                                   # C
            5482 => 'Percentage',                                                     # C
            5495 => 'SublineIndicatorCode',                                           # B
            5501 => 'RatePlanCode',                                                   # I
            6000 => 'LatitudeDegree',                                                 # C
            6002 => 'LongitudeDegree',                                                # C
            6008 => 'HeightMeasure',                                                  # C
            6029 => 'GeographicalPositionCodeQualifier',                              # B
            6060 => 'Quantity',                                                       # C
            6063 => 'QuantityTypeCodeQualifier',                                      # C
            6064 => 'VarianceQuantity',                                               # B
            6066 => 'ControlTotalQuantity',                                           # B
            6069 => 'ControlTotalTypeCodeQualifier',                                  # B
            6071 => 'FrequencyCodeQualifier',                                         # B
            6072 => 'FrequencyRate',                                                  # C
            6074 => 'ConfidencePercent',                                              # B
            6077 => 'ResultRepresentationCode',                                       # B
            6079 => 'ResultNormalcyCode',                                             # B
            6082 => 'DosageDescription',                                              # B
            6083 => 'DosageDescriptionIdentifier',                                    # B
            6085 => 'DosageAdministrationCodeQualifier',                              # B
            6087 => 'ResultValueTypeCodeQualifier',                                   # B
            6096 => 'Altitude',                                                       # B
            6140 => 'WidthMeasure',                                                   # C
            6145 => 'DimensionTypeCodeQualifier',                                     # B
            6152 => 'RangeMaximumQuantity',                                           # C
            6154 => 'NondiscreteMeasurementName',                                     # B
            6155 => 'NondiscreteMeasurementNameCode',                                 # B
            6162 => 'RangeMinimumQuantity',                                           # C
            6167 => 'RangeTypeCodeQualifier',                                         # B
            6168 => 'LengthMeasure',                                                  # C
            6173 => 'SizeTypeCodeQualifier',                                          # B
            6174 => 'SizeMeasure',                                                    # B
            6176 => 'OccurrencesMaximumNumber',                                       # B
            6178 => 'EditFieldLengthMeasure',                                         # B
            6245 => 'TemperatureTypeCodeQualifier',                                   # B
            6246 => 'TemperatureDegree',                                              # B
            6311 => 'MeasurementPurposeCodeQualifier',                                # B
            6313 => 'MeasuredAttributeCode',                                          # C
            6314 => 'Measure',                                                        # C
            6321 => 'MeasurementSignificanceCode',                                    # C
            6331 => 'StatisticTypeCodeQualifier',                                     # B
            6341 => 'ExchangeRateCurrencyMarketIdentifier',                           # C
            6343 => 'CurrencyTypeCodeQualifier',                                      # C
            6345 => 'CurrencyIdentificationCode',                                     # C
            6347 => 'CurrencyUsageCodeQualifier',                                     # C
            6348 => 'CurrencyRate',                                                   # C
            6350 => 'UnitsQuantity',                                                  # C
            6353 => 'UnitTypeCodeQualifier',                                          # C
            6410 => 'MeasurementUnitName',                                            # B
            6411 => 'MeasurementUnitCode',                                            # C
            6412 => 'ClinicalInformationDescription',                                 # B
            6413 => 'ClinicalInformationDescriptionIdentifier',                       # B
            6415 => 'ClinicalInformationTypeCodeQualifier',                           # B
            6426 => 'ProcessStagesQuantity',                                          # B
            6428 => 'ProcessStagesActualQuantity',                                    # B
            6432 => 'SignificantDigitsQuantity',                                      # B
            6434 => 'StatisticalConceptIdentifier',                                   # B
            7001 => 'PhysicalOrLogicalStateTypeCodeQualifier',                        # B
            7006 => 'PhysicalOrLogicalStateDescription',                              # B
            7007 => 'PhysicalOrLogicalStateDescriptionCode',                          # B
            7008 => 'ItemDescription',                                                # C
            7009 => 'ItemDescriptionCode',                                            # C
            7011 => 'ItemAvailabilityCode',                                           # B
            7036 => 'CharacteristicDescription',                                      # C
            7037 => 'CharacteristicDescriptionCode',                                  # C
            7039 => 'SampleSelectionMethodCode',                                      # B
            7045 => 'SampleStateCode',                                                # B
            7047 => 'SampleDirectionCode',                                            # B
            7059 => 'ClassTypeCode',                                                  # B
            7064 => 'TypeOfPackages',                                                 # B
            7065 => 'PackageTypeDescriptionCode',                                     # B
            7073 => 'PackagingTermsAndConditionsCode',                                # B
            7075 => 'PackagingLevelCode',                                             # B
            7077 => 'DescriptionFormatCode',                                          # B
            7081 => 'ItemCharacteristicCode',                                         # B
            7083 => 'ConfigurationOperationCode',                                     # B
            7085 => 'CargoTypeClassificationCode',                                    # B
            7088 => 'DangerousGoodsFlashpointDescription',                            # B
            7102 => 'ShippingMarksDescription',                                       # B
            7106 => 'ShipmentFlashpointDegree',                                       # B
            7110 => 'CharacteristicValueDescription',                                 # B
            7111 => 'CharacteristicValueDescriptionCode',                             # C
            7124 => 'UnitedNationsDangerousGoods(UNDG)Identifier',                    # B
            7130 => 'CustomerShipmentAuthorisationIdentifier',                        # B
            7133 => 'ProductDetailsTypeCodeQualifier',                                # I
            7135 => 'ProductIdentifier',                                              # I
            7139 => 'ProductCharacteristicIdentificationCode',                        # I
            7140 => 'ItemIdentifier',                                                 # C
            7143 => 'ItemTypeIdentificationCode',                                     # C
            7160 => 'SpecialServiceDescription',                                      # C
            7161 => 'SpecialServiceDescriptionCode',                                  # C
            7164 => 'HierarchicalStructureLevelIdentifier',                           # C
            7166 => 'HierarchicalStructureParentIdentifier',                          # B
            7168 => 'LevelNumber',                                                    # B
            7171 => 'HierarchicalStructureRelationshipCode',                          # B
            7173 => 'HierarchyObjectCodeQualifier',                                   # B
            7175 => 'RulePartIdentifier',                                             # B
            7176 => 'RiskObjectSubtypeDescription',                                   # B
            7177 => 'RiskObjectSubtypeDescriptionIdentifier',                         # B
            7179 => 'RiskObjectTypeIdentifier',                                       # B
            7186 => 'ProcessTypeDescription',                                         # B
            7187 => 'ProcessTypeDescriptionCode',                                     # B
            7188 => 'TestMethodRevisionIdentifier',                                   # B
            7190 => 'ProcessDescription',                                             # B
            7191 => 'ProcessDescriptionCode',                                         # C
            7224 => 'PackageQuantity',                                                # B
            7233 => 'PackagingRelatedDescriptionCode',                                # B
            7240 => 'ItemTotalQuantity',                                              # B
            7273 => 'ServiceRequirementCode',                                         # C
            7293 => 'SectorAreaIdentificationCodeQualifier',                          # B
            7294 => 'RequirementOrConditionDescription',                              # B
            7295 => 'RequirementOrConditionDescriptionIdentifier',                    # B
            7297 => 'SetTypeCodeQualifier',                                           # B
            7299 => 'RequirementDesignatorCode',                                      # C
            7357 => 'CommodityIdentificationCode',                                    # B
            7361 => 'CustomsGoodsIdentifier',                                         # B
            7364 => 'ProcessingIndicatorDescription',                                 # B
            7365 => 'ProcessingIndicatorDescriptionCode',                             # C
            7383 => 'SurfaceOrLayerCode',                                             # C
            7402 => 'ObjectIdentifier',                                               # C
            7405 => 'ObjectIdentificationCodeQualifier',                              # C
            7418 => 'HazardousMaterialCategoryName',                                  # B
            7419 => 'HazardousMaterialCategoryNameCode',                              # B
            7429 => 'IndexingStructureCodeQualifier',                                 # B
            7431 => 'AgreementTypeCodeQualifier',                                     # B
            7433 => 'AgreementTypeDescriptionCode',                                   # B
            7434 => 'AgreementTypeDescription',                                       # B
            7436 => 'LevelOneIdentifier',                                             # B
            7438 => 'LevelTwoIdentifier',                                             # B
            7440 => 'LevelThreeIdentifier',                                           # B
            7442 => 'LevelFourIdentifier',                                            # B
            7444 => 'LevelFiveIdentifier',                                            # B
            7446 => 'LevelSixIdentifier',                                             # B
            7449 => 'MembershipTypeCodeQualifier',                                    # B
            7450 => 'MembershipCategoryDescription',                                  # B
            7451 => 'MembershipCategoryDescriptionCode',                              # B
            7452 => 'MembershipStatusDescription',                                    # B
            7453 => 'MembershipStatusDescriptionCode',                                # B
            7455 => 'MembershipLevelCodeQualifier',                                   # B
            7456 => 'MembershipLevelDescription',                                     # B
            7457 => 'MembershipLevelDescriptionCode',                                 # B
            7458 => 'AttendeeCategoryDescription',                                    # B
            7459 => 'AttendeeCategoryDescriptionCode',                                # B
            7491 => 'InventoryTypeCode',                                              # B
            7493 => 'DamageDetailsCodeQualifier',                                     # B
            7495 => 'ObjectTypeCodeQualifier',                                        # B
            7497 => 'StructureComponentFunctionCodeQualifier',                        # B
            7500 => 'DamageTypeDescription',                                          # B
            7501 => 'DamageTypeDescriptionCode',                                      # B
            7502 => 'DamageAreaDescription',                                          # B
            7503 => 'DamageAreaDescriptionCode',                                      # B
            7504 => 'UnitOrComponentTypeDescription',                                 # B
            7505 => 'UnitOrComponentTypeDescriptionCode',                             # B
            7506 => 'ComponentMaterialDescription',                                   # B
            7507 => 'ComponentMaterialDescriptionCode',                               # B
            7508 => 'DamageSeverityDescription',                                      # B
            7509 => 'DamageSeverityDescriptionCode',                                  # B
            7511 => 'MarkingTypeCode',                                                # B
            7512 => 'StructureComponentIdentifier',                                   # B
            7515 => 'StructureTypeCode',                                              # B
            7517 => 'BenefitAndCoverageCode',                                         # I
            7519 => 'UsageQualificationCode',                                         # B
            7521 => 'UsageDescription,Coded',                                         # B
            7522 => 'UsageDescription',                                               # B
            8015 => 'TrafficRestrictionCode',                                         # I
            8017 => 'TrafficRestrictionApplicationCode',                              # I
            8022 => 'FreightAndOtherChargesDescription',                              # B
            8023 => 'FreightAndOtherChargesDescriptionIdentifier',                    # B
            8024 => 'ConveyanceCallPurposeDescription',                               # B
            8025 => 'ConveyanceCallPurposeDescriptionCode',                           # B
            8028 => 'MeansOfTransportJourneyIdentifier',                              # B
            8035 => 'TrafficRestrictionTypeCodeQualifier',                            # I
            8051 => 'TransportStageCodeQualifier',                                    # B
            8053 => 'EquipmentTypeCodeQualifier',                                     # C
            8066 => 'TransportModeName',                                              # B
            8067 => 'TransportModeNameCode',                                          # B
            8077 => 'EquipmentSupplierCode',                                          # B
            8078 => 'AdditionalHazardClassificationIdentifier',                       # B
            8092 => 'HazardCodeVersionIdentifier',                                    # B
            8101 => 'TransitDirectionIndicatorCode',                                  # B
            8126 => 'TransportEmergencyCardIdentifier',                               # B
            8154 => 'EquipmentSizeAndTypeDescription',                                # C
            8155 => 'EquipmentSizeAndTypeDescriptionCode',                            # B
            8158 => 'OrangeHazardPlacardUpperPartIdentifier',                         # B
            8169 => 'FullOrEmptyIndicatorCode',                                       # B
            8178 => 'TransportMeansDescription',                                      # B
            8179 => 'TransportMeansDescriptionCode',                                  # C
            8186 => 'OrangeHazardPlacardLowerPartIdentifier',                         # B
            8211 => 'HazardousCargoTransportAuthorisationCode',                       # B
            8212 => 'TransportMeansIdentificationName',                               # B
            8213 => 'TransportMeansIdentificationNameIdentifier',                     # B
            8215 => 'TransportMeansChangeIndicatorCode',                              # I
            8216 => 'JourneyStopsQuantity',                                           # I
            8219 => 'TravellerAccompaniedByInfantIndicatorCode',                      # I
            8246 => 'DangerousGoodsMarkingIdentifier',                                # B
            8249 => 'EquipmentStatusCode',                                            # B
            8255 => 'PackingInstructionTypeCode',                                     # B
            8260 => 'EquipmentIdentifier',                                            # B
            8273 => 'DangerousGoodsRegulationsCode',                                  # B
            8275 => 'ContainerOrPackageContentsIndicatorCode',                        # B
            8281 => 'TransportMeansOwnershipIndicatorCode',                           # B
            8323 => 'TransportMovementCode',                                          # B
            8332 => 'EquipmentPlanDescription',                                       # B
            8334 => 'MovementTypeDescription',                                        # B
            8335 => 'MovementTypeDescriptionCode',                                    # B
            8339 => 'PackagingDangerLevelCode',                                       # B
            8341 => 'HaulageArrangementsCode',                                        # B
            8351 => 'HazardIdentificationCode',                                       # B
            8364 => 'EmergencyProcedureForShipsIdentifier',                           # B
            8393 => 'ReturnablePackageLoadContentsCode',                              # B
            8395 => 'ReturnablePackageFreightPaymentResponsibilityCode',              # B
            8410 => 'HazardMedicalFirstAidGuideIdentifier',                           # B
            8453 => 'TransportMeansNationalityCode',                                  # B
            8457 => 'ExcessTransportationReasonCode',                                 # B
            8459 => 'ExcessTransportationResponsibilityCode',                         # B
            8461 => 'TunnelRestrictionCode',                                          # B
            9003 => 'EmploymentDetailsCodeQualifier',                                 # B
            9004 => 'EmploymentCategoryDescription',                                  # B
            9005 => 'EmploymentCategoryDescriptionCode',                              # C
            9006 => 'QualificationClassificationDescription',                         # B
            9007 => 'QualificationClassificationDescriptionCode',                     # B
            9008 => 'OccupationDescription',                                          # B
            9009 => 'OccupationDescriptionCode',                                      # B
            9012 => 'StatusReasonDescription',                                        # B
            9013 => 'StatusReasonDescriptionCode',                                    # C
            9015 => 'StatusCategoryCode',                                             # B
            9017 => 'AttributeFunctionCodeQualifier',                                 # C
            9018 => 'AttributeDescription',                                           # C
            9019 => 'AttributeDescriptionCode',                                       # B
            9020 => 'AttributeTypeDescription',                                       # B
            9021 => 'AttributeTypeDescriptionCode',                                   # C
            9023 => 'DefinitionFunctionCode',                                         # B
            9025 => 'DefinitionExtentCode',                                           # B
            9026 => 'EditMaskFormatIdentifier',                                       # B
            9029 => 'ValueDefinitionCodeQualifier',                                   # B
            9031 => 'EditMaskRepresentationCode',                                     # B
            9035 => 'QualificationApplicationAreaCode',                               # B
            9037 => 'QualificationTypeCodeQualifier',                                 # B
            9038 => 'FacilityTypeDescription',                                        # I
            9039 => 'FacilityTypeDescriptionCode',                                    # I
            9040 => 'ReservationIdentifier',                                          # I
            9043 => 'ReservationIdentifierCodeQualifier',                             # I
            9045 => 'BasisCodeQualifier',                                             # B
            9046 => 'BasisTypeDescription',                                           # B
            9047 => 'BasisTypeDescriptionCode',                                       # B
            9048 => 'ApplicabilityTypeDescription',                                   # B
            9049 => 'ApplicabilityTypeDescriptionCode',                               # B
            9051 => 'ApplicabilityCodeQualifier',                                     # B
            9141 => 'RelationshipTypeCodeQualifier',                                  # C
            9142 => 'RelationshipDescription',                                        # C
            9143 => 'RelationshipDescriptionCode',                                    # C
            9146 => 'CompositeDataElementTagIdentifier',                              # B
            9148 => 'DirectoryStatusIdentifier',                                      # B
            9150 => 'SimpleDataElementTagIdentifier',                                 # B
            9153 => 'SimpleDataElementCharacterRepresentationCode',                   # B
            9155 => 'LengthTypeCode',                                                 # B
            9156 => 'SimpleDataElementMaximumLengthMeasure',                          # B
            9158 => 'SimpleDataElementMinimumLengthMeasure',                          # B
            9161 => 'CodeSetIndicatorCode',                                           # B
            9162 => 'DataElementTagIdentifier',                                       # B
            9164 => 'GroupIdentifier',                                                # B
            9166 => 'SegmentTagIdentifier',                                           # B
            9169 => 'DataRepresentationTypeCode',                                     # B
            9170 => 'EventTypeDescription',                                           # B
            9171 => 'EventTypeDescriptionCode',                                       # B
            9172 => 'Event',                                                          # B
            9173 => 'EventDescriptionCode',                                           # B
            9175 => 'DataElementUsageTypeCode',                                       # B
            9213 => 'DutyRegimeTypeCode',                                             # B
            9280 => 'ValidationResultText',                                           # B
            9282 => 'ValidationKeyIdentifier',                                        # B
            9285 => 'ValidationCriteriaCode',                                         # B
            9302 => 'SealingPartyName',                                               # B
            9303 => 'SealingPartyNameCode',                                           # B
            9308 => 'TransportUnitSealIdentifier',                                    # B
            9321 => 'ApplicationErrorCode',                                           # C
            9352 => 'GovernmentProcedure',                                            # 
            9353 => 'GovernmentProcedureCode',                                        # B
            9411 => 'GovernmentInvolvementCode',                                      # B
            9415 => 'GovernmentAgencyIdentificationCode',                             # B
            9416 => 'GovernmentAction',                                               # 
            9417 => 'GovernmentActionCode',                                           # B
            9419 => 'ServiceLayerCode',                                               # B
            9421 => 'ProcessStageCodeQualifier',                                      # B
            9422 => 'ValueText',                                                      # B
            9424 => 'ArrayCellDataDescription',                                       # B
            9426 => 'CodeValueText',                                                  # B
            9428 => 'ArrayCellStructureIdentifier',                                   # B
            9430 => 'FootnoteSetIdentifier',                                          # B
            9432 => 'FootnoteIdentifier',                                             # B
            9434 => 'CodeName',                                                       # B
            9436 => 'ClinicalInterventionDescription',                                # B
            9437 => 'ClinicalInterventionDescriptionCode',                            # B
            9441 => 'ClinicalInterventionTypeCodeQualifier',                          # B
            9443 => 'AttendanceTypeCodeQualifier',                                    # B
            9444 => 'AdmissionTypeDescription',                                       # B
            9445 => 'AdmissionTypeDescriptionCode',                                   # C
            9446 => 'DischargeTypeDescription',                                       # B
            9447 => 'DischargeTypeDescriptionCode',                                   # C
            9448 => 'FileGenerationCommandName',                                      # B
            9450 => 'FileCompressionTechniqueName',                                   # B
            9453 => 'CodeValueSourceCode',                                            # B
            9501 => 'FormulaTypeCodeQualifier',                                       # B
            9502 => 'FormulaName',                                                    # B
            9505 => 'FormulaComplexityCode',                                          # B
            9507 => 'FormulaSequenceCodeQualifier',                                   # B
            9509 => 'FormulaSequenceOperandCode',                                     # B
            9510 => 'FormulaSequenceName',                                            # B
            9601 => 'InformationCategoryCode',                                        # I
            9605 => 'DataCodeQualifier',                                              # I
            9607 => 'YesOrNoIndicatorCode',                                           # I
            9608 => 'ProductName',                                                    # I
            9614 => 'InformationCategoryDescription',                                 # B
            9615 => 'InformationCategoryDescriptionCode',                             # B
            9616 => 'InformationDetailDescription',                                   # B
            9617 => 'InformationDetailDescriptionCode',                               # B
            9619 => 'AdjustmentCategoryCode',                                         # I
            9620 => 'PolicyLimitationIdentifier',                                     # I
            9623 => 'DiagnosisTypeCode',                                              # I
            9625 => 'RelatedCauseCode',                                               # I
            9627 => 'AdmissionSourceCode',                                            # I
            9629 => 'ProcedureModificationCode',                                      # I
            9631 => 'InvoiceTypeCode',                                                # I
            9633 => 'InformationDetailsCodeQualifier',                                # B
            9635 => 'EventDetailsCodeQualifier',                                      # B
            9636 => 'EventCategoryDescription',                                       # B
            9637 => 'EventCategoryDescriptionCode',                                   # B
            9639 => 'DiagnosisCategoryCode',                                          # I
            9641 => 'ServiceBasisCodeQualifier',                                      # I
            9643 => 'SupportingEvidenceTypeCodeQualifier',                            # I
            9645 => 'PayerResponsibilityLevelCode',                                   # I
            9647 => 'CavityZoneCode',                                                 # I
            9649 => 'ProcessingInformationCodeQualifier',                             # B
        );
    }
    return \%code_hash;
}

1;
__END__

