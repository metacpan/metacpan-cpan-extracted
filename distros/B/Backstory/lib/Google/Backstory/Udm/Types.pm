package Google::Backstory::Udm::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Verdict',
    as (Int | Str);

declare 'Reputation',
    as (Int | Str);

declare 'Status',
    as (Int | Str);

declare 'Priority',
    as (Int | Str);

declare 'Reason',
    as (Int | Str);

declare 'ThreatVerdict',
    as (Int | Str);

declare 'UDM',
    as InstanceOf['Google::Backstory::Udm::UDM'];

coerce 'UDM',
    from HashRef, via { 'Google::Backstory::Udm::UDM'->new($_) };

declare 'RepeatedUDM',
    as ArrayRef[UDM()];

coerce 'RepeatedUDM',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::UDM'->new($_) } @$_ ] };

declare 'MapStringUDM',
    as HashRef[UDM()];

declare 'Metadata',
    as InstanceOf['Google::Backstory::Udm::Metadata'];

coerce 'Metadata',
    from HashRef, via { 'Google::Backstory::Udm::Metadata'->new($_) };

declare 'RepeatedMetadata',
    as ArrayRef[Metadata()];

coerce 'RepeatedMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::Metadata'->new($_) } @$_ ] };

declare 'MapStringMetadata',
    as HashRef[Metadata()];

declare 'EventTimestampAttribute',
    as (Int | Str);

declare 'EventType',
    as (Int | Str);

declare 'EnrichmentState',
    as (Int | Str);

declare 'Attribute',
    as InstanceOf['Google::Backstory::Udm::Attribute'];

coerce 'Attribute',
    from HashRef, via { 'Google::Backstory::Udm::Attribute'->new($_) };

declare 'RepeatedAttribute',
    as ArrayRef[Attribute()];

coerce 'RepeatedAttribute',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::Attribute'->new($_) } @$_ ] };

declare 'MapStringAttribute',
    as HashRef[Attribute()];

declare 'Network',
    as InstanceOf['Google::Backstory::Udm::Network'];

coerce 'Network',
    from HashRef, via { 'Google::Backstory::Udm::Network'->new($_) };

declare 'RepeatedNetwork',
    as ArrayRef[Network()];

coerce 'RepeatedNetwork',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::Network'->new($_) } @$_ ] };

declare 'MapStringNetwork',
    as HashRef[Network()];

declare 'Direction',
    as (Int | Str);

declare 'IpProtocol',
    as (Int | Str);

declare 'ApplicationProtocol',
    as (Int | Str);

declare 'ConnectionState',
    as (Int | Str);

declare 'ProxyInfo',
    as InstanceOf['Google::Backstory::Udm::ProxyInfo'];

coerce 'ProxyInfo',
    from HashRef, via { 'Google::Backstory::Udm::ProxyInfo'->new($_) };

declare 'RepeatedProxyInfo',
    as ArrayRef[ProxyInfo()];

coerce 'RepeatedProxyInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::ProxyInfo'->new($_) } @$_ ] };

declare 'MapStringProxyInfo',
    as HashRef[ProxyInfo()];

declare 'Extensions',
    as InstanceOf['Google::Backstory::Udm::Extensions'];

coerce 'Extensions',
    from HashRef, via { 'Google::Backstory::Udm::Extensions'->new($_) };

declare 'RepeatedExtensions',
    as ArrayRef[Extensions()];

coerce 'RepeatedExtensions',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::Extensions'->new($_) } @$_ ] };

declare 'MapStringExtensions',
    as HashRef[Extensions()];

declare 'Authentication',
    as InstanceOf['Google::Backstory::Udm::Authentication'];

coerce 'Authentication',
    from HashRef, via { 'Google::Backstory::Udm::Authentication'->new($_) };

declare 'RepeatedAuthentication',
    as ArrayRef[Authentication()];

coerce 'RepeatedAuthentication',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::Authentication'->new($_) } @$_ ] };

declare 'MapStringAuthentication',
    as HashRef[Authentication()];

declare 'AuthType',
    as (Int | Str);

declare 'Mechanism',
    as (Int | Str);

declare 'AuthenticationStatus',
    as (Int | Str);

declare 'Outcome',
    as (Int | Str);

declare 'LinuxUtmp',
    as InstanceOf['Google::Backstory::Udm::LinuxUtmp'];

coerce 'LinuxUtmp',
    from HashRef, via { 'Google::Backstory::Udm::LinuxUtmp'->new($_) };

declare 'RepeatedLinuxUtmp',
    as ArrayRef[LinuxUtmp()];

coerce 'RepeatedLinuxUtmp',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::LinuxUtmp'->new($_) } @$_ ] };

declare 'MapStringLinuxUtmp',
    as HashRef[LinuxUtmp()];

declare 'RecordType',
    as (Int | Str);

declare 'WindowsEventLog',
    as InstanceOf['Google::Backstory::Udm::WindowsEventLog'];

coerce 'WindowsEventLog',
    from HashRef, via { 'Google::Backstory::Udm::WindowsEventLog'->new($_) };

declare 'RepeatedWindowsEventLog',
    as ArrayRef[WindowsEventLog()];

coerce 'RepeatedWindowsEventLog',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::WindowsEventLog'->new($_) } @$_ ] };

declare 'MapStringWindowsEventLog',
    as HashRef[WindowsEventLog()];

declare 'Channel',
    as (Int | Str);

declare 'ResourceUsage',
    as InstanceOf['Google::Backstory::Udm::ResourceUsage'];

coerce 'ResourceUsage',
    from HashRef, via { 'Google::Backstory::Udm::ResourceUsage'->new($_) };

declare 'RepeatedResourceUsage',
    as ArrayRef[ResourceUsage()];

coerce 'RepeatedResourceUsage',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::ResourceUsage'->new($_) } @$_ ] };

declare 'MapStringResourceUsage',
    as HashRef[ResourceUsage()];

declare 'SystemEventDetails',
    as InstanceOf['Google::Backstory::Udm::SystemEventDetails'];

coerce 'SystemEventDetails',
    from HashRef, via { 'Google::Backstory::Udm::SystemEventDetails'->new($_) };

declare 'RepeatedSystemEventDetails',
    as ArrayRef[SystemEventDetails()];

coerce 'RepeatedSystemEventDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::SystemEventDetails'->new($_) } @$_ ] };

declare 'MapStringSystemEventDetails',
    as HashRef[SystemEventDetails()];

declare 'OutlookMetadata',
    as InstanceOf['Google::Backstory::Udm::OutlookMetadata'];

coerce 'OutlookMetadata',
    from HashRef, via { 'Google::Backstory::Udm::OutlookMetadata'->new($_) };

declare 'RepeatedOutlookMetadata',
    as ArrayRef[OutlookMetadata()];

coerce 'RepeatedOutlookMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::OutlookMetadata'->new($_) } @$_ ] };

declare 'MapStringOutlookMetadata',
    as HashRef[OutlookMetadata()];

declare 'Srum',
    as InstanceOf['Google::Backstory::Udm::Srum'];

coerce 'Srum',
    from HashRef, via { 'Google::Backstory::Udm::Srum'->new($_) };

declare 'RepeatedSrum',
    as ArrayRef[Srum()];

coerce 'RepeatedSrum',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::Srum'->new($_) } @$_ ] };

declare 'MapStringSrum',
    as HashRef[Srum()];

declare 'UserAssist',
    as InstanceOf['Google::Backstory::Udm::UserAssist'];

coerce 'UserAssist',
    from HashRef, via { 'Google::Backstory::Udm::UserAssist'->new($_) };

declare 'RepeatedUserAssist',
    as ArrayRef[UserAssist()];

coerce 'RepeatedUserAssist',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::UserAssist'->new($_) } @$_ ] };

declare 'MapStringUserAssist',
    as HashRef[UserAssist()];

declare 'Vulnerabilities',
    as InstanceOf['Google::Backstory::Udm::Vulnerabilities'];

coerce 'Vulnerabilities',
    from HashRef, via { 'Google::Backstory::Udm::Vulnerabilities'->new($_) };

declare 'RepeatedVulnerabilities',
    as ArrayRef[Vulnerabilities()];

coerce 'RepeatedVulnerabilities',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::Vulnerabilities'->new($_) } @$_ ] };

declare 'MapStringVulnerabilities',
    as HashRef[Vulnerabilities()];

declare 'Vulnerability',
    as InstanceOf['Google::Backstory::Udm::Vulnerability'];

coerce 'Vulnerability',
    from HashRef, via { 'Google::Backstory::Udm::Vulnerability'->new($_) };

declare 'RepeatedVulnerability',
    as ArrayRef[Vulnerability()];

coerce 'RepeatedVulnerability',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::Vulnerability'->new($_) } @$_ ] };

declare 'MapStringVulnerability',
    as HashRef[Vulnerability()];

declare 'Severity',
    as (Int | Str);

declare 'Ftp',
    as InstanceOf['Google::Backstory::Udm::Ftp'];

coerce 'Ftp',
    from HashRef, via { 'Google::Backstory::Udm::Ftp'->new($_) };

declare 'RepeatedFtp',
    as ArrayRef[Ftp()];

coerce 'RepeatedFtp',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::Ftp'->new($_) } @$_ ] };

declare 'MapStringFtp',
    as HashRef[Ftp()];

declare 'Smtp',
    as InstanceOf['Google::Backstory::Udm::Smtp'];

coerce 'Smtp',
    from HashRef, via { 'Google::Backstory::Udm::Smtp'->new($_) };

declare 'RepeatedSmtp',
    as ArrayRef[Smtp()];

coerce 'RepeatedSmtp',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::Smtp'->new($_) } @$_ ] };

declare 'MapStringSmtp',
    as HashRef[Smtp()];

declare 'Email',
    as InstanceOf['Google::Backstory::Udm::Email'];

coerce 'Email',
    from HashRef, via { 'Google::Backstory::Udm::Email'->new($_) };

declare 'RepeatedEmail',
    as ArrayRef[Email()];

coerce 'RepeatedEmail',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::Email'->new($_) } @$_ ] };

declare 'MapStringEmail',
    as HashRef[Email()];

declare 'Process',
    as InstanceOf['Google::Backstory::Udm::Process'];

coerce 'Process',
    from HashRef, via { 'Google::Backstory::Udm::Process'->new($_) };

declare 'RepeatedProcess',
    as ArrayRef[Process()];

coerce 'RepeatedProcess',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::Process'->new($_) } @$_ ] };

declare 'MapStringProcess',
    as HashRef[Process()];

declare 'TokenElevationType',
    as (Int | Str);

declare 'State',
    as (Int | Str);

declare 'AnalyticsMetadata',
    as InstanceOf['Google::Backstory::Udm::AnalyticsMetadata'];

coerce 'AnalyticsMetadata',
    from HashRef, via { 'Google::Backstory::Udm::AnalyticsMetadata'->new($_) };

declare 'RepeatedAnalyticsMetadata',
    as ArrayRef[AnalyticsMetadata()];

coerce 'RepeatedAnalyticsMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::AnalyticsMetadata'->new($_) } @$_ ] };

declare 'MapStringAnalyticsMetadata',
    as HashRef[AnalyticsMetadata()];

declare 'FindingVariable',
    as InstanceOf['Google::Backstory::Udm::FindingVariable'];

coerce 'FindingVariable',
    from HashRef, via { 'Google::Backstory::Udm::FindingVariable'->new($_) };

declare 'RepeatedFindingVariable',
    as ArrayRef[FindingVariable()];

coerce 'RepeatedFindingVariable',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::FindingVariable'->new($_) } @$_ ] };

declare 'MapStringFindingVariable',
    as HashRef[FindingVariable()];

declare 'Type',
    as (Int | Str);

declare 'SecurityResult',
    as InstanceOf['Google::Backstory::Udm::SecurityResult'];

coerce 'SecurityResult',
    from HashRef, via { 'Google::Backstory::Udm::SecurityResult'->new($_) };

declare 'RepeatedSecurityResult',
    as ArrayRef[SecurityResult()];

coerce 'RepeatedSecurityResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::SecurityResult'->new($_) } @$_ ] };

declare 'MapStringSecurityResult',
    as HashRef[SecurityResult()];

declare 'VerdictResponse',
    as (Int | Str);

declare 'IoCStatsType',
    as (Int | Str);

declare 'VerdictType',
    as (Int | Str);

declare 'SecurityCategory',
    as (Int | Str);

declare 'AlertState',
    as (Int | Str);

declare 'Action',
    as (Int | Str);

declare 'ProductSeverity',
    as (Int | Str);

declare 'ProductConfidence',
    as (Int | Str);

declare 'ProductPriority',
    as (Int | Str);

declare 'ThreatStatus',
    as (Int | Str);

declare 'ThreatCollectionType',
    as (Int | Str);

declare 'Association',
    as InstanceOf['Google::Backstory::Udm::SecurityResult::Association'];

coerce 'Association',
    from HashRef, via { 'Google::Backstory::Udm::SecurityResult::Association'->new($_) };

declare 'RepeatedAssociation',
    as ArrayRef[Association()];

coerce 'RepeatedAssociation',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::SecurityResult::Association'->new($_) } @$_ ] };

declare 'MapStringAssociation',
    as HashRef[Association()];

declare 'AssociationType',
    as (Int | Str);

declare 'AssociationAlias',
    as InstanceOf['Google::Backstory::Udm::SecurityResult::Association::AssociationAlias'];

coerce 'AssociationAlias',
    from HashRef, via { 'Google::Backstory::Udm::SecurityResult::Association::AssociationAlias'->new($_) };

declare 'RepeatedAssociationAlias',
    as ArrayRef[AssociationAlias()];

coerce 'RepeatedAssociationAlias',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::SecurityResult::Association::AssociationAlias'->new($_) } @$_ ] };

declare 'MapStringAssociationAlias',
    as HashRef[AssociationAlias()];

declare 'Source',
    as InstanceOf['Google::Backstory::Udm::SecurityResult::Source'];

coerce 'Source',
    from HashRef, via { 'Google::Backstory::Udm::SecurityResult::Source'->new($_) };

declare 'RepeatedSource',
    as ArrayRef[Source()];

coerce 'RepeatedSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::SecurityResult::Source'->new($_) } @$_ ] };

declare 'MapStringSource',
    as HashRef[Source()];

declare 'ProviderMLVerdict',
    as InstanceOf['Google::Backstory::Udm::SecurityResult::ProviderMLVerdict'];

coerce 'ProviderMLVerdict',
    from HashRef, via { 'Google::Backstory::Udm::SecurityResult::ProviderMLVerdict'->new($_) };

declare 'RepeatedProviderMLVerdict',
    as ArrayRef[ProviderMLVerdict()];

coerce 'RepeatedProviderMLVerdict',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::SecurityResult::ProviderMLVerdict'->new($_) } @$_ ] };

declare 'MapStringProviderMLVerdict',
    as HashRef[ProviderMLVerdict()];

declare 'AnalystVerdict',
    as InstanceOf['Google::Backstory::Udm::SecurityResult::AnalystVerdict'];

coerce 'AnalystVerdict',
    from HashRef, via { 'Google::Backstory::Udm::SecurityResult::AnalystVerdict'->new($_) };

declare 'RepeatedAnalystVerdict',
    as ArrayRef[AnalystVerdict()];

coerce 'RepeatedAnalystVerdict',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::SecurityResult::AnalystVerdict'->new($_) } @$_ ] };

declare 'MapStringAnalystVerdict',
    as HashRef[AnalystVerdict()];

declare 'IoCStats',
    as InstanceOf['Google::Backstory::Udm::SecurityResult::IoCStats'];

coerce 'IoCStats',
    from HashRef, via { 'Google::Backstory::Udm::SecurityResult::IoCStats'->new($_) };

declare 'RepeatedIoCStats',
    as ArrayRef[IoCStats()];

coerce 'RepeatedIoCStats',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::SecurityResult::IoCStats'->new($_) } @$_ ] };

declare 'MapStringIoCStats',
    as HashRef[IoCStats()];

declare 'VerdictInfo',
    as InstanceOf['Google::Backstory::Udm::SecurityResult::VerdictInfo'];

coerce 'VerdictInfo',
    from HashRef, via { 'Google::Backstory::Udm::SecurityResult::VerdictInfo'->new($_) };

declare 'RepeatedVerdictInfo',
    as ArrayRef[VerdictInfo()];

coerce 'RepeatedVerdictInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::SecurityResult::VerdictInfo'->new($_) } @$_ ] };

declare 'MapStringVerdictInfo',
    as HashRef[VerdictInfo()];

declare 'Verdict',
    as InstanceOf['Google::Backstory::Udm::SecurityResult::Verdict'];

coerce 'Verdict',
    from HashRef, via { 'Google::Backstory::Udm::SecurityResult::Verdict'->new($_) };

declare 'RepeatedVerdict',
    as ArrayRef[Verdict()];

coerce 'RepeatedVerdict',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::SecurityResult::Verdict'->new($_) } @$_ ] };

declare 'MapStringVerdict',
    as HashRef[Verdict()];

declare 'ThreatCollectionItem',
    as InstanceOf['Google::Backstory::Udm::SecurityResult::ThreatCollectionItem'];

coerce 'ThreatCollectionItem',
    from HashRef, via { 'Google::Backstory::Udm::SecurityResult::ThreatCollectionItem'->new($_) };

declare 'RepeatedThreatCollectionItem',
    as ArrayRef[ThreatCollectionItem()];

coerce 'RepeatedThreatCollectionItem',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::SecurityResult::ThreatCollectionItem'->new($_) } @$_ ] };

declare 'MapStringThreatCollectionItem',
    as HashRef[ThreatCollectionItem()];

declare 'VariablesEntry',
    as InstanceOf['Google::Backstory::Udm::SecurityResult::VariablesEntry'];

coerce 'VariablesEntry',
    from HashRef, via { 'Google::Backstory::Udm::SecurityResult::VariablesEntry'->new($_) };

declare 'RepeatedVariablesEntry',
    as ArrayRef[VariablesEntry()];

coerce 'RepeatedVariablesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::SecurityResult::VariablesEntry'->new($_) } @$_ ] };

declare 'MapStringVariablesEntry',
    as HashRef[VariablesEntry()];

declare 'PeFileMetadata',
    as InstanceOf['Google::Backstory::Udm::PeFileMetadata'];

coerce 'PeFileMetadata',
    from HashRef, via { 'Google::Backstory::Udm::PeFileMetadata'->new($_) };

declare 'RepeatedPeFileMetadata',
    as ArrayRef[PeFileMetadata()];

coerce 'RepeatedPeFileMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::PeFileMetadata'->new($_) } @$_ ] };

declare 'MapStringPeFileMetadata',
    as HashRef[PeFileMetadata()];

declare 'FileMetadata',
    as InstanceOf['Google::Backstory::Udm::FileMetadata'];

coerce 'FileMetadata',
    from HashRef, via { 'Google::Backstory::Udm::FileMetadata'->new($_) };

declare 'RepeatedFileMetadata',
    as ArrayRef[FileMetadata()];

coerce 'RepeatedFileMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::FileMetadata'->new($_) } @$_ ] };

declare 'MapStringFileMetadata',
    as HashRef[FileMetadata()];

declare 'File',
    as InstanceOf['Google::Backstory::Udm::File'];

coerce 'File',
    from HashRef, via { 'Google::Backstory::Udm::File'->new($_) };

declare 'RepeatedFile',
    as ArrayRef[File()];

coerce 'RepeatedFile',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::File'->new($_) } @$_ ] };

declare 'MapStringFile',
    as HashRef[File()];

declare 'FileType',
    as (Int | Str);

declare 'NtfsFileMetadata',
    as InstanceOf['Google::Backstory::Udm::NtfsFileMetadata'];

coerce 'NtfsFileMetadata',
    from HashRef, via { 'Google::Backstory::Udm::NtfsFileMetadata'->new($_) };

declare 'RepeatedNtfsFileMetadata',
    as ArrayRef[NtfsFileMetadata()];

coerce 'RepeatedNtfsFileMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::NtfsFileMetadata'->new($_) } @$_ ] };

declare 'MapStringNtfsFileMetadata',
    as HashRef[NtfsFileMetadata()];

declare 'PrefetchFileMetadata',
    as InstanceOf['Google::Backstory::Udm::PrefetchFileMetadata'];

coerce 'PrefetchFileMetadata',
    from HashRef, via { 'Google::Backstory::Udm::PrefetchFileMetadata'->new($_) };

declare 'RepeatedPrefetchFileMetadata',
    as ArrayRef[PrefetchFileMetadata()];

coerce 'RepeatedPrefetchFileMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::PrefetchFileMetadata'->new($_) } @$_ ] };

declare 'MapStringPrefetchFileMetadata',
    as HashRef[PrefetchFileMetadata()];

declare 'UsnJournal',
    as InstanceOf['Google::Backstory::Udm::UsnJournal'];

coerce 'UsnJournal',
    from HashRef, via { 'Google::Backstory::Udm::UsnJournal'->new($_) };

declare 'RepeatedUsnJournal',
    as ArrayRef[UsnJournal()];

coerce 'RepeatedUsnJournal',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::UsnJournal'->new($_) } @$_ ] };

declare 'MapStringUsnJournal',
    as HashRef[UsnJournal()];

declare 'Attribute',
    as (Int | Str);

declare 'Reason',
    as (Int | Str);

declare 'AppCompatMetadata',
    as InstanceOf['Google::Backstory::Udm::AppCompatMetadata'];

coerce 'AppCompatMetadata',
    from HashRef, via { 'Google::Backstory::Udm::AppCompatMetadata'->new($_) };

declare 'RepeatedAppCompatMetadata',
    as ArrayRef[AppCompatMetadata()];

coerce 'RepeatedAppCompatMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::AppCompatMetadata'->new($_) } @$_ ] };

declare 'MapStringAppCompatMetadata',
    as HashRef[AppCompatMetadata()];

declare 'FileMetadataPE',
    as InstanceOf['Google::Backstory::Udm::FileMetadataPE'];

coerce 'FileMetadataPE',
    from HashRef, via { 'Google::Backstory::Udm::FileMetadataPE'->new($_) };

declare 'RepeatedFileMetadataPE',
    as ArrayRef[FileMetadataPE()];

coerce 'RepeatedFileMetadataPE',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::FileMetadataPE'->new($_) } @$_ ] };

declare 'MapStringFileMetadataPE',
    as HashRef[FileMetadataPE()];

declare 'FileMetadataPeResourceInfo',
    as InstanceOf['Google::Backstory::Udm::FileMetadataPeResourceInfo'];

coerce 'FileMetadataPeResourceInfo',
    from HashRef, via { 'Google::Backstory::Udm::FileMetadataPeResourceInfo'->new($_) };

declare 'RepeatedFileMetadataPeResourceInfo',
    as ArrayRef[FileMetadataPeResourceInfo()];

coerce 'RepeatedFileMetadataPeResourceInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::FileMetadataPeResourceInfo'->new($_) } @$_ ] };

declare 'MapStringFileMetadataPeResourceInfo',
    as HashRef[FileMetadataPeResourceInfo()];

declare 'SignatureInfo',
    as InstanceOf['Google::Backstory::Udm::SignatureInfo'];

coerce 'SignatureInfo',
    from HashRef, via { 'Google::Backstory::Udm::SignatureInfo'->new($_) };

declare 'RepeatedSignatureInfo',
    as ArrayRef[SignatureInfo()];

coerce 'RepeatedSignatureInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::SignatureInfo'->new($_) } @$_ ] };

declare 'MapStringSignatureInfo',
    as HashRef[SignatureInfo()];

declare 'FileMetadataSignatureInfo',
    as InstanceOf['Google::Backstory::Udm::FileMetadataSignatureInfo'];

coerce 'FileMetadataSignatureInfo',
    from HashRef, via { 'Google::Backstory::Udm::FileMetadataSignatureInfo'->new($_) };

declare 'RepeatedFileMetadataSignatureInfo',
    as ArrayRef[FileMetadataSignatureInfo()];

coerce 'RepeatedFileMetadataSignatureInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::FileMetadataSignatureInfo'->new($_) } @$_ ] };

declare 'MapStringFileMetadataSignatureInfo',
    as HashRef[FileMetadataSignatureInfo()];

declare 'SignerInfo',
    as InstanceOf['Google::Backstory::Udm::SignerInfo'];

coerce 'SignerInfo',
    from HashRef, via { 'Google::Backstory::Udm::SignerInfo'->new($_) };

declare 'RepeatedSignerInfo',
    as ArrayRef[SignerInfo()];

coerce 'RepeatedSignerInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::SignerInfo'->new($_) } @$_ ] };

declare 'MapStringSignerInfo',
    as HashRef[SignerInfo()];

declare 'FileMetadataCodesign',
    as InstanceOf['Google::Backstory::Udm::FileMetadataCodesign'];

coerce 'FileMetadataCodesign',
    from HashRef, via { 'Google::Backstory::Udm::FileMetadataCodesign'->new($_) };

declare 'RepeatedFileMetadataCodesign',
    as ArrayRef[FileMetadataCodesign()];

coerce 'RepeatedFileMetadataCodesign',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::FileMetadataCodesign'->new($_) } @$_ ] };

declare 'MapStringFileMetadataCodesign',
    as HashRef[FileMetadataCodesign()];

declare 'X509',
    as InstanceOf['Google::Backstory::Udm::X509'];

coerce 'X509',
    from HashRef, via { 'Google::Backstory::Udm::X509'->new($_) };

declare 'RepeatedX509',
    as ArrayRef[X509()];

coerce 'RepeatedX509',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::X509'->new($_) } @$_ ] };

declare 'MapStringX509',
    as HashRef[X509()];

declare 'PDFInfo',
    as InstanceOf['Google::Backstory::Udm::PDFInfo'];

coerce 'PDFInfo',
    from HashRef, via { 'Google::Backstory::Udm::PDFInfo'->new($_) };

declare 'RepeatedPDFInfo',
    as ArrayRef[PDFInfo()];

coerce 'RepeatedPDFInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::PDFInfo'->new($_) } @$_ ] };

declare 'MapStringPDFInfo',
    as HashRef[PDFInfo()];

declare 'StringToInt64MapEntry',
    as InstanceOf['Google::Backstory::Udm::StringToInt64MapEntry'];

coerce 'StringToInt64MapEntry',
    from HashRef, via { 'Google::Backstory::Udm::StringToInt64MapEntry'->new($_) };

declare 'RepeatedStringToInt64MapEntry',
    as ArrayRef[StringToInt64MapEntry()];

coerce 'RepeatedStringToInt64MapEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::StringToInt64MapEntry'->new($_) } @$_ ] };

declare 'MapStringStringToInt64MapEntry',
    as HashRef[StringToInt64MapEntry()];

declare 'FileMetadataSection',
    as InstanceOf['Google::Backstory::Udm::FileMetadataSection'];

coerce 'FileMetadataSection',
    from HashRef, via { 'Google::Backstory::Udm::FileMetadataSection'->new($_) };

declare 'RepeatedFileMetadataSection',
    as ArrayRef[FileMetadataSection()];

coerce 'RepeatedFileMetadataSection',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::FileMetadataSection'->new($_) } @$_ ] };

declare 'MapStringFileMetadataSection',
    as HashRef[FileMetadataSection()];

declare 'FileMetadataImports',
    as InstanceOf['Google::Backstory::Udm::FileMetadataImports'];

coerce 'FileMetadataImports',
    from HashRef, via { 'Google::Backstory::Udm::FileMetadataImports'->new($_) };

declare 'RepeatedFileMetadataImports',
    as ArrayRef[FileMetadataImports()];

coerce 'RepeatedFileMetadataImports',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::FileMetadataImports'->new($_) } @$_ ] };

declare 'MapStringFileMetadataImports',
    as HashRef[FileMetadataImports()];

declare 'ExifInfo',
    as InstanceOf['Google::Backstory::Udm::ExifInfo'];

coerce 'ExifInfo',
    from HashRef, via { 'Google::Backstory::Udm::ExifInfo'->new($_) };

declare 'RepeatedExifInfo',
    as ArrayRef[ExifInfo()];

coerce 'RepeatedExifInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::ExifInfo'->new($_) } @$_ ] };

declare 'MapStringExifInfo',
    as HashRef[ExifInfo()];

declare 'Prevalence',
    as InstanceOf['Google::Backstory::Udm::Prevalence'];

coerce 'Prevalence',
    from HashRef, via { 'Google::Backstory::Udm::Prevalence'->new($_) };

declare 'RepeatedPrevalence',
    as ArrayRef[Prevalence()];

coerce 'RepeatedPrevalence',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::Prevalence'->new($_) } @$_ ] };

declare 'MapStringPrevalence',
    as HashRef[Prevalence()];

declare 'Dns',
    as InstanceOf['Google::Backstory::Udm::Dns'];

coerce 'Dns',
    from HashRef, via { 'Google::Backstory::Udm::Dns'->new($_) };

declare 'RepeatedDns',
    as ArrayRef[Dns()];

coerce 'RepeatedDns',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::Dns'->new($_) } @$_ ] };

declare 'MapStringDns',
    as HashRef[Dns()];

declare 'Question',
    as InstanceOf['Google::Backstory::Udm::Dns::Question'];

coerce 'Question',
    from HashRef, via { 'Google::Backstory::Udm::Dns::Question'->new($_) };

declare 'RepeatedQuestion',
    as ArrayRef[Question()];

coerce 'RepeatedQuestion',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::Dns::Question'->new($_) } @$_ ] };

declare 'MapStringQuestion',
    as HashRef[Question()];

declare 'ResourceRecord',
    as InstanceOf['Google::Backstory::Udm::Dns::ResourceRecord'];

coerce 'ResourceRecord',
    from HashRef, via { 'Google::Backstory::Udm::Dns::ResourceRecord'->new($_) };

declare 'RepeatedResourceRecord',
    as ArrayRef[ResourceRecord()];

coerce 'RepeatedResourceRecord',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::Dns::ResourceRecord'->new($_) } @$_ ] };

declare 'MapStringResourceRecord',
    as HashRef[ResourceRecord()];

declare 'Dhcp',
    as InstanceOf['Google::Backstory::Udm::Dhcp'];

coerce 'Dhcp',
    from HashRef, via { 'Google::Backstory::Udm::Dhcp'->new($_) };

declare 'RepeatedDhcp',
    as ArrayRef[Dhcp()];

coerce 'RepeatedDhcp',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::Dhcp'->new($_) } @$_ ] };

declare 'MapStringDhcp',
    as HashRef[Dhcp()];

declare 'OpCode',
    as (Int | Str);

declare 'MessageType',
    as (Int | Str);

declare 'Option',
    as InstanceOf['Google::Backstory::Udm::Dhcp::Option'];

coerce 'Option',
    from HashRef, via { 'Google::Backstory::Udm::Dhcp::Option'->new($_) };

declare 'RepeatedOption',
    as ArrayRef[Option()];

coerce 'RepeatedOption',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::Dhcp::Option'->new($_) } @$_ ] };

declare 'MapStringOption',
    as HashRef[Option()];

declare 'Certificate',
    as InstanceOf['Google::Backstory::Udm::Certificate'];

coerce 'Certificate',
    from HashRef, via { 'Google::Backstory::Udm::Certificate'->new($_) };

declare 'RepeatedCertificate',
    as ArrayRef[Certificate()];

coerce 'RepeatedCertificate',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::Certificate'->new($_) } @$_ ] };

declare 'MapStringCertificate',
    as HashRef[Certificate()];

declare 'Tls',
    as InstanceOf['Google::Backstory::Udm::Tls'];

coerce 'Tls',
    from HashRef, via { 'Google::Backstory::Udm::Tls'->new($_) };

declare 'RepeatedTls',
    as ArrayRef[Tls()];

coerce 'RepeatedTls',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::Tls'->new($_) } @$_ ] };

declare 'MapStringTls',
    as HashRef[Tls()];

declare 'Client',
    as InstanceOf['Google::Backstory::Udm::Tls::Client'];

coerce 'Client',
    from HashRef, via { 'Google::Backstory::Udm::Tls::Client'->new($_) };

declare 'RepeatedClient',
    as ArrayRef[Client()];

coerce 'RepeatedClient',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::Tls::Client'->new($_) } @$_ ] };

declare 'MapStringClient',
    as HashRef[Client()];

declare 'Server',
    as InstanceOf['Google::Backstory::Udm::Tls::Server'];

coerce 'Server',
    from HashRef, via { 'Google::Backstory::Udm::Tls::Server'->new($_) };

declare 'RepeatedServer',
    as ArrayRef[Server()];

coerce 'RepeatedServer',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::Tls::Server'->new($_) } @$_ ] };

declare 'MapStringServer',
    as HashRef[Server()];

declare 'Http',
    as InstanceOf['Google::Backstory::Udm::Http'];

coerce 'Http',
    from HashRef, via { 'Google::Backstory::Udm::Http'->new($_) };

declare 'RepeatedHttp',
    as ArrayRef[Http()];

coerce 'RepeatedHttp',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::Http'->new($_) } @$_ ] };

declare 'MapStringHttp',
    as HashRef[Http()];

declare 'Browser',
    as InstanceOf['Google::Backstory::Udm::Browser'];

coerce 'Browser',
    from HashRef, via { 'Google::Backstory::Udm::Browser'->new($_) };

declare 'RepeatedBrowser',
    as ArrayRef[Browser()];

coerce 'RepeatedBrowser',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::Browser'->new($_) } @$_ ] };

declare 'MapStringBrowser',
    as HashRef[Browser()];

declare 'BrowserType',
    as (Int | Str);

declare 'UrlVisitType',
    as (Int | Str);

declare 'VisitSource',
    as (Int | Str);

declare 'Cookie',
    as InstanceOf['Google::Backstory::Udm::Browser::Cookie'];

coerce 'Cookie',
    from HashRef, via { 'Google::Backstory::Udm::Browser::Cookie'->new($_) };

declare 'RepeatedCookie',
    as ArrayRef[Cookie()];

coerce 'RepeatedCookie',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::Browser::Cookie'->new($_) } @$_ ] };

declare 'MapStringCookie',
    as HashRef[Cookie()];

declare 'CookieSameSite',
    as (Int | Str);

declare 'Hardware',
    as InstanceOf['Google::Backstory::Udm::Hardware'];

coerce 'Hardware',
    from HashRef, via { 'Google::Backstory::Udm::Hardware'->new($_) };

declare 'RepeatedHardware',
    as ArrayRef[Hardware()];

coerce 'RepeatedHardware',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::Hardware'->new($_) } @$_ ] };

declare 'MapStringHardware',
    as HashRef[Hardware()];

declare 'PlatformSoftware',
    as InstanceOf['Google::Backstory::Udm::PlatformSoftware'];

coerce 'PlatformSoftware',
    from HashRef, via { 'Google::Backstory::Udm::PlatformSoftware'->new($_) };

declare 'RepeatedPlatformSoftware',
    as ArrayRef[PlatformSoftware()];

coerce 'RepeatedPlatformSoftware',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::PlatformSoftware'->new($_) } @$_ ] };

declare 'MapStringPlatformSoftware',
    as HashRef[PlatformSoftware()];

declare 'Software',
    as InstanceOf['Google::Backstory::Udm::Software'];

coerce 'Software',
    from HashRef, via { 'Google::Backstory::Udm::Software'->new($_) };

declare 'RepeatedSoftware',
    as ArrayRef[Software()];

coerce 'RepeatedSoftware',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::Software'->new($_) } @$_ ] };

declare 'MapStringSoftware',
    as HashRef[Software()];

declare 'Asset',
    as InstanceOf['Google::Backstory::Udm::Asset'];

coerce 'Asset',
    from HashRef, via { 'Google::Backstory::Udm::Asset'->new($_) };

declare 'RepeatedAsset',
    as ArrayRef[Asset()];

coerce 'RepeatedAsset',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::Asset'->new($_) } @$_ ] };

declare 'MapStringAsset',
    as HashRef[Asset()];

declare 'AssetType',
    as (Int | Str);

declare 'DeploymentStatus',
    as (Int | Str);

declare 'User',
    as InstanceOf['Google::Backstory::Udm::User'];

coerce 'User',
    from HashRef, via { 'Google::Backstory::Udm::User'->new($_) };

declare 'RepeatedUser',
    as ArrayRef[User()];

coerce 'RepeatedUser',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::User'->new($_) } @$_ ] };

declare 'MapStringUser',
    as HashRef[User()];

declare 'AccountType',
    as (Int | Str);

declare 'Role',
    as (Int | Str);

declare 'TimeOff',
    as InstanceOf['Google::Backstory::Udm::TimeOff'];

coerce 'TimeOff',
    from HashRef, via { 'Google::Backstory::Udm::TimeOff'->new($_) };

declare 'RepeatedTimeOff',
    as ArrayRef[TimeOff()];

coerce 'RepeatedTimeOff',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::TimeOff'->new($_) } @$_ ] };

declare 'MapStringTimeOff',
    as HashRef[TimeOff()];

declare 'Permission',
    as InstanceOf['Google::Backstory::Udm::Permission'];

coerce 'Permission',
    from HashRef, via { 'Google::Backstory::Udm::Permission'->new($_) };

declare 'RepeatedPermission',
    as ArrayRef[Permission()];

coerce 'RepeatedPermission',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::Permission'->new($_) } @$_ ] };

declare 'MapStringPermission',
    as HashRef[Permission()];

declare 'PermissionType',
    as (Int | Str);

declare 'Role',
    as InstanceOf['Google::Backstory::Udm::Role'];

coerce 'Role',
    from HashRef, via { 'Google::Backstory::Udm::Role'->new($_) };

declare 'RepeatedRole',
    as ArrayRef[Role()];

coerce 'RepeatedRole',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::Role'->new($_) } @$_ ] };

declare 'MapStringRole',
    as HashRef[Role()];

declare 'Type',
    as (Int | Str);

declare 'Group',
    as InstanceOf['Google::Backstory::Udm::Group'];

coerce 'Group',
    from HashRef, via { 'Google::Backstory::Udm::Group'->new($_) };

declare 'RepeatedGroup',
    as ArrayRef[Group()];

coerce 'RepeatedGroup',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::Group'->new($_) } @$_ ] };

declare 'MapStringGroup',
    as HashRef[Group()];

declare 'Registry',
    as InstanceOf['Google::Backstory::Udm::Registry'];

coerce 'Registry',
    from HashRef, via { 'Google::Backstory::Udm::Registry'->new($_) };

declare 'RepeatedRegistry',
    as ArrayRef[Registry()];

coerce 'RepeatedRegistry',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::Registry'->new($_) } @$_ ] };

declare 'MapStringRegistry',
    as HashRef[Registry()];

declare 'Type',
    as (Int | Str);

declare 'WmiPersistenceItem',
    as InstanceOf['Google::Backstory::Udm::WmiPersistenceItem'];

coerce 'WmiPersistenceItem',
    from HashRef, via { 'Google::Backstory::Udm::WmiPersistenceItem'->new($_) };

declare 'RepeatedWmiPersistenceItem',
    as ArrayRef[WmiPersistenceItem()];

coerce 'RepeatedWmiPersistenceItem',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::WmiPersistenceItem'->new($_) } @$_ ] };

declare 'MapStringWmiPersistenceItem',
    as HashRef[WmiPersistenceItem()];

declare 'Location',
    as InstanceOf['Google::Backstory::Udm::Location'];

coerce 'Location',
    from HashRef, via { 'Google::Backstory::Udm::Location'->new($_) };

declare 'RepeatedLocation',
    as ArrayRef[Location()];

coerce 'RepeatedLocation',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::Location'->new($_) } @$_ ] };

declare 'MapStringLocation',
    as HashRef[Location()];

declare 'ScheduledTask',
    as InstanceOf['Google::Backstory::Udm::ScheduledTask'];

coerce 'ScheduledTask',
    from HashRef, via { 'Google::Backstory::Udm::ScheduledTask'->new($_) };

declare 'RepeatedScheduledTask',
    as ArrayRef[ScheduledTask()];

coerce 'RepeatedScheduledTask',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::ScheduledTask'->new($_) } @$_ ] };

declare 'MapStringScheduledTask',
    as HashRef[ScheduledTask()];

declare 'WindowsScheduledTask',
    as InstanceOf['Google::Backstory::Udm::WindowsScheduledTask'];

coerce 'WindowsScheduledTask',
    from HashRef, via { 'Google::Backstory::Udm::WindowsScheduledTask'->new($_) };

declare 'RepeatedWindowsScheduledTask',
    as ArrayRef[WindowsScheduledTask()];

coerce 'RepeatedWindowsScheduledTask',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::WindowsScheduledTask'->new($_) } @$_ ] };

declare 'MapStringWindowsScheduledTask',
    as HashRef[WindowsScheduledTask()];

declare 'TaskState',
    as (Int | Str);

declare 'TaskLogonType',
    as (Int | Str);

declare 'TaskAction',
    as InstanceOf['Google::Backstory::Udm::WindowsScheduledTask::TaskAction'];

coerce 'TaskAction',
    from HashRef, via { 'Google::Backstory::Udm::WindowsScheduledTask::TaskAction'->new($_) };

declare 'RepeatedTaskAction',
    as ArrayRef[TaskAction()];

coerce 'RepeatedTaskAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::WindowsScheduledTask::TaskAction'->new($_) } @$_ ] };

declare 'MapStringTaskAction',
    as HashRef[TaskAction()];

declare 'ActionType',
    as (Int | Str);

declare 'TaskTrigger',
    as InstanceOf['Google::Backstory::Udm::WindowsScheduledTask::TaskTrigger'];

coerce 'TaskTrigger',
    from HashRef, via { 'Google::Backstory::Udm::WindowsScheduledTask::TaskTrigger'->new($_) };

declare 'RepeatedTaskTrigger',
    as ArrayRef[TaskTrigger()];

coerce 'RepeatedTaskTrigger',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::WindowsScheduledTask::TaskTrigger'->new($_) } @$_ ] };

declare 'MapStringTaskTrigger',
    as HashRef[TaskTrigger()];

declare 'TriggerType',
    as (Int | Str);

declare 'ScheduledCronTask',
    as InstanceOf['Google::Backstory::Udm::ScheduledCronTask'];

coerce 'ScheduledCronTask',
    from HashRef, via { 'Google::Backstory::Udm::ScheduledCronTask'->new($_) };

declare 'RepeatedScheduledCronTask',
    as ArrayRef[ScheduledCronTask()];

coerce 'RepeatedScheduledCronTask',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::ScheduledCronTask'->new($_) } @$_ ] };

declare 'MapStringScheduledCronTask',
    as HashRef[ScheduledCronTask()];

declare 'ScheduledAnacronTask',
    as InstanceOf['Google::Backstory::Udm::ScheduledAnacronTask'];

coerce 'ScheduledAnacronTask',
    from HashRef, via { 'Google::Backstory::Udm::ScheduledAnacronTask'->new($_) };

declare 'RepeatedScheduledAnacronTask',
    as ArrayRef[ScheduledAnacronTask()];

coerce 'RepeatedScheduledAnacronTask',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::ScheduledAnacronTask'->new($_) } @$_ ] };

declare 'MapStringScheduledAnacronTask',
    as HashRef[ScheduledAnacronTask()];

declare 'Volume',
    as InstanceOf['Google::Backstory::Udm::Volume'];

coerce 'Volume',
    from HashRef, via { 'Google::Backstory::Udm::Volume'->new($_) };

declare 'RepeatedVolume',
    as ArrayRef[Volume()];

coerce 'RepeatedVolume',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::Volume'->new($_) } @$_ ] };

declare 'MapStringVolume',
    as HashRef[Volume()];

declare 'Service',
    as InstanceOf['Google::Backstory::Udm::Service'];

coerce 'Service',
    from HashRef, via { 'Google::Backstory::Udm::Service'->new($_) };

declare 'RepeatedService',
    as ArrayRef[Service()];

coerce 'RepeatedService',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::Service'->new($_) } @$_ ] };

declare 'MapStringService',
    as HashRef[Service()];

declare 'ServiceType',
    as (Int | Str);

declare 'StartupType',
    as (Int | Str);

declare 'State',
    as (Int | Str);

declare 'Resource',
    as InstanceOf['Google::Backstory::Udm::Resource'];

coerce 'Resource',
    from HashRef, via { 'Google::Backstory::Udm::Resource'->new($_) };

declare 'RepeatedResource',
    as ArrayRef[Resource()];

coerce 'RepeatedResource',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::Resource'->new($_) } @$_ ] };

declare 'MapStringResource',
    as HashRef[Resource()];

declare 'ResourceType',
    as (Int | Str);

declare 'Label',
    as InstanceOf['Google::Backstory::Udm::Label'];

coerce 'Label',
    from HashRef, via { 'Google::Backstory::Udm::Label'->new($_) };

declare 'RepeatedLabel',
    as ArrayRef[Label()];

coerce 'RepeatedLabel',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::Label'->new($_) } @$_ ] };

declare 'MapStringLabel',
    as HashRef[Label()];

declare 'Cloud',
    as InstanceOf['Google::Backstory::Udm::Cloud'];

coerce 'Cloud',
    from HashRef, via { 'Google::Backstory::Udm::Cloud'->new($_) };

declare 'RepeatedCloud',
    as ArrayRef[Cloud()];

coerce 'RepeatedCloud',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::Cloud'->new($_) } @$_ ] };

declare 'MapStringCloud',
    as HashRef[Cloud()];

declare 'CloudEnvironment',
    as (Int | Str);

declare 'Artifact',
    as InstanceOf['Google::Backstory::Udm::Artifact'];

coerce 'Artifact',
    from HashRef, via { 'Google::Backstory::Udm::Artifact'->new($_) };

declare 'RepeatedArtifact',
    as ArrayRef[Artifact()];

coerce 'RepeatedArtifact',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::Artifact'->new($_) } @$_ ] };

declare 'MapStringArtifact',
    as HashRef[Artifact()];

declare 'Tunnels',
    as InstanceOf['Google::Backstory::Udm::Tunnels'];

coerce 'Tunnels',
    from HashRef, via { 'Google::Backstory::Udm::Tunnels'->new($_) };

declare 'RepeatedTunnels',
    as ArrayRef[Tunnels()];

coerce 'RepeatedTunnels',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::Tunnels'->new($_) } @$_ ] };

declare 'MapStringTunnels',
    as HashRef[Tunnels()];

declare 'ArtifactClient',
    as InstanceOf['Google::Backstory::Udm::ArtifactClient'];

coerce 'ArtifactClient',
    from HashRef, via { 'Google::Backstory::Udm::ArtifactClient'->new($_) };

declare 'RepeatedArtifactClient',
    as ArrayRef[ArtifactClient()];

coerce 'RepeatedArtifactClient',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::ArtifactClient'->new($_) } @$_ ] };

declare 'MapStringArtifactClient',
    as HashRef[ArtifactClient()];

declare 'Favicon',
    as InstanceOf['Google::Backstory::Udm::Favicon'];

coerce 'Favicon',
    from HashRef, via { 'Google::Backstory::Udm::Favicon'->new($_) };

declare 'RepeatedFavicon',
    as ArrayRef[Favicon()];

coerce 'RepeatedFavicon',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::Favicon'->new($_) } @$_ ] };

declare 'MapStringFavicon',
    as HashRef[Favicon()];

declare 'DNSRecord',
    as InstanceOf['Google::Backstory::Udm::DNSRecord'];

coerce 'DNSRecord',
    from HashRef, via { 'Google::Backstory::Udm::DNSRecord'->new($_) };

declare 'RepeatedDNSRecord',
    as ArrayRef[DNSRecord()];

coerce 'RepeatedDNSRecord',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::DNSRecord'->new($_) } @$_ ] };

declare 'MapStringDNSRecord',
    as HashRef[DNSRecord()];

declare 'SSLCertificate',
    as InstanceOf['Google::Backstory::Udm::SSLCertificate'];

coerce 'SSLCertificate',
    from HashRef, via { 'Google::Backstory::Udm::SSLCertificate'->new($_) };

declare 'RepeatedSSLCertificate',
    as ArrayRef[SSLCertificate()];

coerce 'RepeatedSSLCertificate',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::SSLCertificate'->new($_) } @$_ ] };

declare 'MapStringSSLCertificate',
    as HashRef[SSLCertificate()];

declare 'CertSignature',
    as InstanceOf['Google::Backstory::Udm::SSLCertificate::CertSignature'];

coerce 'CertSignature',
    from HashRef, via { 'Google::Backstory::Udm::SSLCertificate::CertSignature'->new($_) };

declare 'RepeatedCertSignature',
    as ArrayRef[CertSignature()];

coerce 'RepeatedCertSignature',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::SSLCertificate::CertSignature'->new($_) } @$_ ] };

declare 'MapStringCertSignature',
    as HashRef[CertSignature()];

declare 'AuthorityKeyId',
    as InstanceOf['Google::Backstory::Udm::SSLCertificate::AuthorityKeyId'];

coerce 'AuthorityKeyId',
    from HashRef, via { 'Google::Backstory::Udm::SSLCertificate::AuthorityKeyId'->new($_) };

declare 'RepeatedAuthorityKeyId',
    as ArrayRef[AuthorityKeyId()];

coerce 'RepeatedAuthorityKeyId',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::SSLCertificate::AuthorityKeyId'->new($_) } @$_ ] };

declare 'MapStringAuthorityKeyId',
    as HashRef[AuthorityKeyId()];

declare 'Extension',
    as InstanceOf['Google::Backstory::Udm::SSLCertificate::Extension'];

coerce 'Extension',
    from HashRef, via { 'Google::Backstory::Udm::SSLCertificate::Extension'->new($_) };

declare 'RepeatedExtension',
    as ArrayRef[Extension()];

coerce 'RepeatedExtension',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::SSLCertificate::Extension'->new($_) } @$_ ] };

declare 'MapStringExtension',
    as HashRef[Extension()];

declare 'Subject',
    as InstanceOf['Google::Backstory::Udm::SSLCertificate::Subject'];

coerce 'Subject',
    from HashRef, via { 'Google::Backstory::Udm::SSLCertificate::Subject'->new($_) };

declare 'RepeatedSubject',
    as ArrayRef[Subject()];

coerce 'RepeatedSubject',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::SSLCertificate::Subject'->new($_) } @$_ ] };

declare 'MapStringSubject',
    as HashRef[Subject()];

declare 'RSA',
    as InstanceOf['Google::Backstory::Udm::SSLCertificate::RSA'];

coerce 'RSA',
    from HashRef, via { 'Google::Backstory::Udm::SSLCertificate::RSA'->new($_) };

declare 'RepeatedRSA',
    as ArrayRef[RSA()];

coerce 'RepeatedRSA',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::SSLCertificate::RSA'->new($_) } @$_ ] };

declare 'MapStringRSA',
    as HashRef[RSA()];

declare 'EC',
    as InstanceOf['Google::Backstory::Udm::SSLCertificate::EC'];

coerce 'EC',
    from HashRef, via { 'Google::Backstory::Udm::SSLCertificate::EC'->new($_) };

declare 'RepeatedEC',
    as ArrayRef[EC()];

coerce 'RepeatedEC',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::SSLCertificate::EC'->new($_) } @$_ ] };

declare 'MapStringEC',
    as HashRef[EC()];

declare 'PublicKey',
    as InstanceOf['Google::Backstory::Udm::SSLCertificate::PublicKey'];

coerce 'PublicKey',
    from HashRef, via { 'Google::Backstory::Udm::SSLCertificate::PublicKey'->new($_) };

declare 'RepeatedPublicKey',
    as ArrayRef[PublicKey()];

coerce 'RepeatedPublicKey',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::SSLCertificate::PublicKey'->new($_) } @$_ ] };

declare 'MapStringPublicKey',
    as HashRef[PublicKey()];

declare 'Validity',
    as InstanceOf['Google::Backstory::Udm::SSLCertificate::Validity'];

coerce 'Validity',
    from HashRef, via { 'Google::Backstory::Udm::SSLCertificate::Validity'->new($_) };

declare 'RepeatedValidity',
    as ArrayRef[Validity()];

coerce 'RepeatedValidity',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::SSLCertificate::Validity'->new($_) } @$_ ] };

declare 'MapStringValidity',
    as HashRef[Validity()];

declare 'PopularityRank',
    as InstanceOf['Google::Backstory::Udm::PopularityRank'];

coerce 'PopularityRank',
    from HashRef, via { 'Google::Backstory::Udm::PopularityRank'->new($_) };

declare 'RepeatedPopularityRank',
    as ArrayRef[PopularityRank()];

coerce 'RepeatedPopularityRank',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::PopularityRank'->new($_) } @$_ ] };

declare 'MapStringPopularityRank',
    as HashRef[PopularityRank()];

declare 'Tracker',
    as InstanceOf['Google::Backstory::Udm::Tracker'];

coerce 'Tracker',
    from HashRef, via { 'Google::Backstory::Udm::Tracker'->new($_) };

declare 'RepeatedTracker',
    as ArrayRef[Tracker()];

coerce 'RepeatedTracker',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::Tracker'->new($_) } @$_ ] };

declare 'MapStringTracker',
    as HashRef[Tracker()];

declare 'Url',
    as InstanceOf['Google::Backstory::Udm::Url'];

coerce 'Url',
    from HashRef, via { 'Google::Backstory::Udm::Url'->new($_) };

declare 'RepeatedUrl',
    as ArrayRef[Url()];

coerce 'RepeatedUrl',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::Url'->new($_) } @$_ ] };

declare 'MapStringUrl',
    as HashRef[Url()];

declare 'Domain',
    as InstanceOf['Google::Backstory::Udm::Domain'];

coerce 'Domain',
    from HashRef, via { 'Google::Backstory::Udm::Domain'->new($_) };

declare 'RepeatedDomain',
    as ArrayRef[Domain()];

coerce 'RepeatedDomain',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::Domain'->new($_) } @$_ ] };

declare 'MapStringDomain',
    as HashRef[Domain()];

declare 'Noun',
    as InstanceOf['Google::Backstory::Udm::Noun'];

coerce 'Noun',
    from HashRef, via { 'Google::Backstory::Udm::Noun'->new($_) };

declare 'RepeatedNoun',
    as ArrayRef[Noun()];

coerce 'RepeatedNoun',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::Noun'->new($_) } @$_ ] };

declare 'MapStringNoun',
    as HashRef[Noun()];

declare 'Platform',
    as (Int | Str);

declare 'Investigation',
    as InstanceOf['Google::Backstory::Udm::Investigation'];

coerce 'Investigation',
    from HashRef, via { 'Google::Backstory::Udm::Investigation'->new($_) };

declare 'RepeatedInvestigation',
    as ArrayRef[Investigation()];

coerce 'RepeatedInvestigation',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::Investigation'->new($_) } @$_ ] };

declare 'MapStringInvestigation',
    as HashRef[Investigation()];

declare 'Tags',
    as InstanceOf['Google::Backstory::Udm::Tags'];

coerce 'Tags',
    from HashRef, via { 'Google::Backstory::Udm::Tags'->new($_) };

declare 'RepeatedTags',
    as ArrayRef[Tags()];

coerce 'RepeatedTags',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::Tags'->new($_) } @$_ ] };

declare 'MapStringTags',
    as HashRef[Tags()];

declare 'AttackDetails',
    as InstanceOf['Google::Backstory::Udm::AttackDetails'];

coerce 'AttackDetails',
    from HashRef, via { 'Google::Backstory::Udm::AttackDetails'->new($_) };

declare 'RepeatedAttackDetails',
    as ArrayRef[AttackDetails()];

coerce 'RepeatedAttackDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::AttackDetails'->new($_) } @$_ ] };

declare 'MapStringAttackDetails',
    as HashRef[AttackDetails()];

declare 'Tactic',
    as InstanceOf['Google::Backstory::Udm::AttackDetails::Tactic'];

coerce 'Tactic',
    from HashRef, via { 'Google::Backstory::Udm::AttackDetails::Tactic'->new($_) };

declare 'RepeatedTactic',
    as ArrayRef[Tactic()];

coerce 'RepeatedTactic',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::AttackDetails::Tactic'->new($_) } @$_ ] };

declare 'MapStringTactic',
    as HashRef[Tactic()];

declare 'Technique',
    as InstanceOf['Google::Backstory::Udm::AttackDetails::Technique'];

coerce 'Technique',
    from HashRef, via { 'Google::Backstory::Udm::AttackDetails::Technique'->new($_) };

declare 'RepeatedTechnique',
    as ArrayRef[Technique()];

coerce 'RepeatedTechnique',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::AttackDetails::Technique'->new($_) } @$_ ] };

declare 'MapStringTechnique',
    as HashRef[Technique()];

declare 'BoolSequence',
    as InstanceOf['Google::Backstory::Udm::BoolSequence'];

coerce 'BoolSequence',
    from HashRef, via { 'Google::Backstory::Udm::BoolSequence'->new($_) };

declare 'RepeatedBoolSequence',
    as ArrayRef[BoolSequence()];

coerce 'RepeatedBoolSequence',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::BoolSequence'->new($_) } @$_ ] };

declare 'MapStringBoolSequence',
    as HashRef[BoolSequence()];

declare 'BytesSequence',
    as InstanceOf['Google::Backstory::Udm::BytesSequence'];

coerce 'BytesSequence',
    from HashRef, via { 'Google::Backstory::Udm::BytesSequence'->new($_) };

declare 'RepeatedBytesSequence',
    as ArrayRef[BytesSequence()];

coerce 'RepeatedBytesSequence',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::BytesSequence'->new($_) } @$_ ] };

declare 'MapStringBytesSequence',
    as HashRef[BytesSequence()];

declare 'DoubleSequence',
    as InstanceOf['Google::Backstory::Udm::DoubleSequence'];

coerce 'DoubleSequence',
    from HashRef, via { 'Google::Backstory::Udm::DoubleSequence'->new($_) };

declare 'RepeatedDoubleSequence',
    as ArrayRef[DoubleSequence()];

coerce 'RepeatedDoubleSequence',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::DoubleSequence'->new($_) } @$_ ] };

declare 'MapStringDoubleSequence',
    as HashRef[DoubleSequence()];

declare 'Int64Sequence',
    as InstanceOf['Google::Backstory::Udm::Int64Sequence'];

coerce 'Int64Sequence',
    from HashRef, via { 'Google::Backstory::Udm::Int64Sequence'->new($_) };

declare 'RepeatedInt64Sequence',
    as ArrayRef[Int64Sequence()];

coerce 'RepeatedInt64Sequence',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::Int64Sequence'->new($_) } @$_ ] };

declare 'MapStringInt64Sequence',
    as HashRef[Int64Sequence()];

declare 'Uint64Sequence',
    as InstanceOf['Google::Backstory::Udm::Uint64Sequence'];

coerce 'Uint64Sequence',
    from HashRef, via { 'Google::Backstory::Udm::Uint64Sequence'->new($_) };

declare 'RepeatedUint64Sequence',
    as ArrayRef[Uint64Sequence()];

coerce 'RepeatedUint64Sequence',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::Uint64Sequence'->new($_) } @$_ ] };

declare 'MapStringUint64Sequence',
    as HashRef[Uint64Sequence()];

declare 'StringSequence',
    as InstanceOf['Google::Backstory::Udm::StringSequence'];

coerce 'StringSequence',
    from HashRef, via { 'Google::Backstory::Udm::StringSequence'->new($_) };

declare 'RepeatedStringSequence',
    as ArrayRef[StringSequence()];

coerce 'RepeatedStringSequence',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::StringSequence'->new($_) } @$_ ] };

declare 'MapStringStringSequence',
    as HashRef[StringSequence()];

declare 'GroupedFields',
    as InstanceOf['Google::Backstory::Udm::GroupedFields'];

coerce 'GroupedFields',
    from HashRef, via { 'Google::Backstory::Udm::GroupedFields'->new($_) };

declare 'RepeatedGroupedFields',
    as ArrayRef[GroupedFields()];

coerce 'RepeatedGroupedFields',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Udm::GroupedFields'->new($_) } @$_ ] };

declare 'MapStringGroupedFields',
    as HashRef[GroupedFields()];

1;

__END__

=head1 NAME

Google::Backstory::Udm::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
