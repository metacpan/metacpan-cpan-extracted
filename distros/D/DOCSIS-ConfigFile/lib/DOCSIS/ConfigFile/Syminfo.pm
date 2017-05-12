package DOCSIS::ConfigFile::Syminfo;

=head1 NAME

DOCSIS::ConfigFile::Syminfo - Symbol information for a DOCSIS config file

=head1 DESCRIPTION

This module holds many pre-defined DOCSIS 1.x and 2.0 TLVs. The
definitions are used to translate between binary and something that
is human readable.

NOTE: DOCSIS 3.0 is also supported, since the main differences is in
the physical layer and not the config file.

=head1 CONFIGURATION TREE

Here is the complete structure of possible config parameters:

  BaselinePrivacy => {
    AuthGraceTime     => uint, # 1..6047999
    AuthRejectTimeout => uint, # 1..600
    AuthTimeout       => uint, # 1..30
    OperTimeout       => uint, # 1..10
    ReAuthTimeout     => uint, # 1..30
    ReKeyTimeout      => uint, # 1..10
    SAMapMaxRetries   => uint, # 0..10
    SAMapWaitTimeout  => uint, # 1..10
    TEKGraceTime      => uint, # 1..302399
  },
  ClassOfService => {
    ClassID       => str,    # 1..16
    GuaranteedUp  => uint,   # 0..10000000
    MaxBurstUp    => ushort, # 0..65535
    MaxRateDown   => uint,   # 0..52000000
    MaxRateUp     => uint,   # 0..10000000
    PriorityUp    => uchar,  # 0..7
    PrivacyEnable => uchar,  # 0..1
  },
  CpeMacAddress       => ether, # "aabbccdddeeff"
  DocsisTwoEnable     => uchar, # 0..1
  DownstreamFrequency => uint,  # 88000000..860000000
  DsChannelList       => {
    DefaultScanTimeout => ushort # 0..65535
    DsFreqRange        => {
      DsFreqRangeEnd      => uint,   # 0..4294967295
      DsFreqRangeStart    => uint,   # 0..4294967295
      DsFreqRangeStepSize => uint,   # 0..4294967295
      DsFreqRangeTimeout  => ushort, # 0..65535
    },
    SingleDsChannel => {
      SingleDsFrequency => uint,   # 0..4294967295
      SingleDsTimeout   => ushort, # 0..65535
    },
  },
  DsPacketClass => {
    ActivationState   => uchar,  # 0..1
    ClassifierId      => ushort, # 1..65535
    ClassifierRef     => uchar,  # 1..255
    DscAction         => uchar,  # 0..2
    IEEE802Classifier => {
      UserPriority => ushort,
      VlanID       => ushort,
    },
    IpPacketClassifier => {
      DstPortEnd   => ushort, # 0..65535
      DstPortStart => ushort, # 0..65535
      IpDstAddr    => ip, # 1.2.3.4
      IpDstMask    => ip, # 1.2.3.4
      IpProto      => ushort, # 0..257
      IpSrcAddr    => ip, # 1.2.3.4
      IpSrcMask    => ip, # 1.2.3.4
      IpTos        => hexstr,
      SrcPortEnd   => ushort, # 0..65535
      SrcPortStart => ushort, # 0..65535
    },
  },
  DsServiceFlow => {
    ActQosParamsTimeout => ushort,  # 0..65535
    AdmQosParamsTimeout => ushort,  # 0..65535
    DsServiceFlowId     => uint,    # 1..4294967295
    DsServiceFlowRef    => ushort,  # 1..65535
    DsVendorSpecific    => {
      id      => ether, # "0x0011ee",
      options => [uchar, hexstr, ... ], # 30, "0xff", ...
    },
    MaxDsLatency        => uint,
    MaxRateSustained    => uint,    # 0..4294967295
    MaxTrafficBurst     => uint,    # 0..4294967295
    MinReservedRate     => uint,    # 0..4294967295
    MinResPacketSize    => ushort,  # 0..65535
    QosParamSetType     => uchar,   # 0..255
    ServiceClassName    => stringz, # 2..16
    TrafficPriority     => uchar,   # 0..7
  },
  GlobalPrivacyEnable => uchar,    # 0..1
  MaxClassifiers      => ushort,
  MaxCPE              => uchar,    # 1..254
  MfgCVCData          => hexstr,   # 0x308203813082
  ModemCapabilities   => {
    BaselinePrivacySupport => uchar, # 0..1
    ConcatenationSupport   => uchar, # 0..1
    DCCSupport             => uchar, # 0..1
    DownstreamSAIDSupport  => uchar, # 0..255
    FragmentationSupport   => uchar, # 0..1
    IGMPSupport            => uchar, # 0..1
    ModemDocsisVersion     => uchar, # 0..2
    PHSSupport             => uchar, # 0..1
    UpstreamSIDSupport     => uchar, # 0..255
  },
  NetworkAccess      => uchar, # 0..1
  PHS                => {
    PHSClassifierId   => ushort, # 1..65535
    PHSClassifierRef  => uchar,  # 1..255
    PHSField          => hexstr, # 1..255
    PHSIndex          => uchar,  # 1..255
    PHSMask           => hexstr, # 1..255
    PHSServiceFlowId  => uint,   # 1..4294967295
    PHSServiceFlowRef => ushort, # 1..65535
    PHSSize           => uchar,  # 1..255
    PHSVerify         => uchar,  # 0..1
  },
  SnmpCpeAccessControl => uchar,       # 0..1
  SnmpMibObject        => snmp_object, # 1..255
  SnmpV3Kickstart      => {
    SnmpV3MgrPublicNumber => hexstr, # 1..514
    SnmpV3SecurityName    => string, # 1..16
  },
  SnmpV3TrapReceiver => {
    SnmpV3TrapRxFilterOID    => ushort, # 1..5
    SnmpV3TrapRxIP           => ip, # 1.2.3.4
    SnmpV3TrapRxPort         => ushort,
    SnmpV3TrapRxRetries      => ushort, # 0..65535
    SnmpV3TrapRxSecurityName => string, # 1..16
    SnmpV3TrapRxTimeout      => ushort, # 0..65535
    SnmpV3TrapRxType         => ushort, # 1..5
  },
  SubMgmtControl    => hexstr,      # 3..3
  SubMgmtCpeTable   => hexstr,
  SubMgmtFilters    => ushort_list, # 4..4
  SwUpgradeFilename => string,      # "bootfile.bin"
  SwUpgradeServer   => ip, # 1.2.3.4
  TestMode          => hexstr,      # 0..1
  TftpModemAddress  => ip, # 1.2.3.4
  TftpTimestamp     => uint,        # 0..4294967295
  UpstreamChannelId => uchar,       # 0..255
  UsPacketClass     => {
    ActivationState   => uchar,  # 0..1
    ClassifierId      => ushort, # 1..65535
    ClassifierRef     => uchar,  # 1..255
    DscAction         => uchar,  # 0..2
    IEEE802Classifier => {
      UserPriority => ushort,
      VlanID       => ushort,
    },
    IpPacketClassifier => {
      DstPortEnd   => ushort, # 0..65535
      DstPortStart => ushort, # 0..65535
      IpDstAddr    => ip, # 1.2.3.4
      IpDstMask    => ip, # 1.2.3.4
      IpProto      => ushort, # 0..257
      IpSrcAddr    => ip, # 1.2.3.4
      IpSrcMask    => ip, # 1.2.3.4
      IpTos        => hexstr,
      SrcPortEnd   => ushort, # 0..65535
      SrcPortStart => ushort, # 0..65535
    },
  },
  UsServiceFlow => {
    ActQosParamsTimeout  => ushort,  # 0..65535
    AdmQosParamsTimeout  => ushort,  # 0..65535
    GrantsPerInterval    => uchar,   # 0..127
    IpTosOverwrite       => hexstr,  # 0..255
    MaxConcatenatedBurst => ushort,  # 0..65535
    MaxRateSustained     => uint,
    MaxTrafficBurst      => uint,
    MinReservedRate      => uint,
    MinResPacketSize     => ushort,  # 0..65535
    NominalGrantInterval => uint,
    NominalPollInterval  => uint,
    QosParamSetType      => uchar,   # 0..255
    RequestOrTxPolicy    => hexstr,  # 0..255
    SchedulingType       => uchar,   # 0..6
    ServiceClassName     => stringz, # 2..16
    ToleratedGrantJitter => uint,
    ToleratedPollJitter  => uint,
    TrafficPriority      => uchar,   # 0..7
    UnsolicitedGrantSize => ushort,  # 0..65535
    UsServiceFlowId      => uint,    # 1..4294967295
    UsServiceFlowRef     => ushort,  # 1..65535
    UsVendorSpecific     => {
      id      => ether, # "0x0011ee",
      options => [uchar, hexstr, ... ], # 30, "0xff", ...
    },
  },
  VendorSpecific => {
    id      => ether, # "0x0011ee",
    options => [uchar, hexstr, ... ], # 30, "0xff", ...
  },

=cut

use strict;
use warnings;
use constant CAN_TRANSLATE_OID => $ENV{DOCSIS_CAN_TRANSLATE_OID} // eval 'require SNMP;1' || 0;
use constant DEBUG => $ENV{DOCSIS_CONFIGFILE_DEBUG} || 0;

if (CAN_TRANSLATE_OID) {
  require File::Basename;
  require File::Spec;
  my $oid_dir = File::Spec->rel2abs(File::Spec->catdir(File::Basename::dirname(__FILE__), 'mibs'));
  warn "[DOCSIS] Adding OID directory $oid_dir\n" if DEBUG;
  SNMP::addMibDirs($oid_dir);
  SNMP::loadModules('ALL');
}

my %FROM_CODE;
my %FROM_ID;
my @OBJECT_ATTRIBUTES = qw( id code pcode func l_limit u_limit length );

# This datastructure should be considered internal
our @CMTS_MIC = qw(
  DownstreamFrequency UpstreamChannelId NetworkAccess
  ClassOfService      BaselinePrivacy   VendorSpecific
  CmMic               MaxCPE            TftpTimestamp
  TftpModemAddress    UsPacketClass     DsPacketClass
  UsServiceFlow       DsServiceFlow     MaxClassifiers
  GlobalPrivacyEnable PHS               SubMgmtControl
  SubMgmtCpeTable     SubMgmtFilters    TestMode
);

# This datastructure should be considered internal
our $TREE = {
  BaselinePrivacy => {
    code   => 17,
    func   => "nested",
    lsize  => 1,
    limit  => [0, 0],
    nested => {
      AuthGraceTime     => {code => 3, func => "uint", lsize => 1, limit => [1, 6047999]},
      AuthRejectTimeout => {code => 7, func => "uint", lsize => 1, limit => [1, 600]},
      AuthTimeout       => {code => 1, func => "uint", lsize => 1, limit => [1, 30]},
      OperTimeout       => {code => 4, func => "uint", lsize => 1, limit => [1, 10]},
      ReAuthTimeout     => {code => 2, func => "uint", lsize => 1, limit => [1, 30]},
      ReKeyTimeout      => {code => 5, func => "uint", lsize => 1, limit => [1, 10]},
      SAMapMaxRetries   => {code => 9, func => "uint", lsize => 1, limit => [0, 10]},
      SAMapWaitTimeout  => {code => 8, func => "uint", lsize => 1, limit => [1, 10]},
      TEKGraceTime      => {code => 6, func => "uint", lsize => 1, limit => [1, 302399]},
    },
  },
  ClassOfService => {
    code   => 4,
    func   => "nested",
    lsize  => 1,
    limit  => [0, 0],
    nested => {
      ClassID       => {code => 1, func => "uchar",  lsize => 1, limit => [1, 16]},
      GuaranteedUp  => {code => 5, func => "uint",   lsize => 1, limit => [0, 10000000]},
      MaxBurstUp    => {code => 6, func => "ushort", lsize => 1, limit => [0, 65535]},
      MaxRateDown   => {code => 2, func => "uint",   lsize => 1, limit => [0, 52000000]},
      MaxRateUp     => {code => 3, func => "uint",   lsize => 1, limit => [0, 10000000]},
      PriorityUp    => {code => 4, func => "uchar",  lsize => 1, limit => [0, 7]},
      PrivacyEnable => {code => 7, func => "uchar",  lsize => 1, limit => [0, 1]},
    },
  },
  CmMic               => {code => 6,  func => "mic",   lsize => 1, limit => [0,        0]},
  CmtsMic             => {code => 7,  func => "mic",   lsize => 1, limit => [0,        0]},
  CpeMacAddress       => {code => 14, func => "ether", lsize => 1, limit => [0,        0]},
  DocsisTwoEnable     => {code => 39, func => "uchar", lsize => 1, limit => [0,        1]},
  DownstreamFrequency => {code => 1,  func => "uint",  lsize => 1, limit => [88000000, 860000000]},
  DsChannelList       => {
    code   => 41,
    func   => "nested",
    lsize  => 1,
    limit  => [1, 255],
    nested => {
      DefaultScanTimeout => {code => 3, func => "ushort", lsize => 1, limit => [0, 65535]},
      DsFreqRange        => {
        code   => 2,
        func   => "nested",
        lsize  => 1,
        limit  => [1, 255],
        nested => {
          DsFreqRangeEnd      => {code => 3, func => "uint",   lsize => 1, limit => [0, 4294967295]},
          DsFreqRangeStart    => {code => 2, func => "uint",   lsize => 1, limit => [0, 4294967295]},
          DsFreqRangeStepSize => {code => 4, func => "uint",   lsize => 1, limit => [0, 4294967295]},
          DsFreqRangeTimeout  => {code => 1, func => "ushort", lsize => 1, limit => [0, 65535]},
        },
      },
      SingleDsChannel => {
        code   => 1,
        func   => "nested",
        lsize  => 1,
        limit  => [1, 255],
        nested => {
          SingleDsFrequency => {code => 2, func => "uint",   lsize => 1, limit => [0, 4294967295]},
          SingleDsTimeout   => {code => 1, func => "ushort", lsize => 1, limit => [0, 65535]},
        },
      },
    },
  },
  DsPacketClass => {
    code   => 23,
    func   => "nested",
    lsize  => 1,
    limit  => [0, 0],
    nested => {
      ActivationState   => {code => 6, func => "uchar",  lsize => 1, limit => [0, 1]},
      ClassifierId      => {code => 2, func => "ushort", lsize => 1, limit => [1, 65535]},
      ClassifierRef     => {code => 1, func => "uchar",  lsize => 1, limit => [1, 255]},
      DscAction         => {code => 7, func => "uchar",  lsize => 1, limit => [0, 2]},
      IEEE802Classifier => {
        code   => 11,
        func   => "nested",
        lsize  => 1,
        limit  => [0, 0],
        nested => {
          UserPriority => {code => 1, func => "ushort", lsize => 1, limit => [0, 0]},
          VlanID       => {code => 2, func => "ushort", lsize => 1, limit => [0, 0]},
        },
      },
      IpPacketClassifier => {
        code   => 9,
        func   => "nested",
        lsize  => 1,
        limit  => [0, 0],
        nested => {
          DstPortEnd   => {code => 10, func => "ushort", lsize => 1, limit => [0, 65535]},
          DstPortStart => {code => 9,  func => "ushort", lsize => 1, limit => [0, 65535]},
          IpDstAddr    => {code => 5,  func => "ip",     lsize => 1, limit => [0, 0]},
          IpDstMask    => {code => 6,  func => "ip",     lsize => 1, limit => [0, 0]},
          IpProto      => {code => 2,  func => "ushort", lsize => 1, limit => [0, 257]},
          IpSrcAddr    => {code => 3,  func => "ip",     lsize => 1, limit => [0, 0]},
          IpSrcMask    => {code => 4,  func => "ip",     lsize => 1, limit => [0, 0]},
          IpTos        => {code => 1,  func => "hexstr", lsize => 1, limit => [0, 0]},
          SrcPortEnd   => {code => 8,  func => "ushort", lsize => 1, limit => [0, 65535]},
          SrcPortStart => {code => 7,  func => "ushort", lsize => 1, limit => [0, 65535]},
        },
      },
      LLCPacketClassifier => {
        code   => 10,
        func   => "nested",
        lsize  => 1,
        limit  => [0, 0],
        nested => {
          DstMacAddress => {code => 1, func => "ether",  lsize => 1, limit => [0, 0]},
          EtherType     => {code => 3, func => "hexstr", lsize => 1, limit => [0, 0]},
          SrcMacAddress => {code => 2, func => "ether",  lsize => 1, limit => [0, 0]},
        },
      },
      RulePriority   => {code => 5, func => "uchar",  lsize => 1, limit => [0, 255]},
      ServiceFlowId  => {code => 4, func => "uint",   lsize => 1, limit => [1, 4294967295]},
      ServiceFlowRef => {code => 3, func => "ushort", lsize => 1, limit => [1, 65535]},
    },
  },
  DsServiceFlow => {
    code   => 25,
    func   => "nested",
    lsize  => 1,
    limit  => [0, 0],
    nested => {
      ActQosParamsTimeout => {code => 12, func => "ushort",  lsize => 1, limit => [0, 65535]},
      AdmQosParamsTimeout => {code => 13, func => "ushort",  lsize => 1, limit => [0, 65535]},
      DsServiceFlowId     => {code => 2,  func => "uint",    lsize => 1, limit => [1, 4294967295]},
      DsServiceFlowRef    => {code => 1,  func => "ushort",  lsize => 1, limit => [1, 65535]},
      DsVendorSpecific    => {code => 43, func => "vendor",  lsize => 1, limit => [0, 0]},
      MaxDsLatency        => {code => 14, func => "uint",    lsize => 1, limit => [0, 0]},
      MaxRateSustained    => {code => 8,  func => "uint",    lsize => 1, limit => [0, 4294967295]},
      MaxTrafficBurst     => {code => 9,  func => "uint",    lsize => 1, limit => [0, 4294967295]},
      MinReservedRate     => {code => 10, func => "uint",    lsize => 1, limit => [0, 4294967295]},
      MinResPacketSize    => {code => 11, func => "ushort",  lsize => 1, limit => [0, 65535]},
      QosParamSetType     => {code => 6,  func => "uchar",   lsize => 1, limit => [0, 255]},
      ServiceClassName    => {code => 4,  func => "stringz", lsize => 1, limit => [2, 16]},
      TrafficPriority     => {code => 7,  func => "uchar",   lsize => 1, limit => [0, 7]},
    },
  },
  GenericTLV          => {code => 255, func => "no_value", lsize => 1, limit => [0, 0]},
  GlobalPrivacyEnable => {code => 29,  func => "uchar",    lsize => 1, limit => [0, 0]},
  MaxClassifiers      => {code => 28,  func => "ushort",   lsize => 1, limit => [0, 0]},
  MaxCPE              => {code => 18,  func => "uchar",    lsize => 1, limit => [1, 254]},
  MfgCVCData          => {code => 32,  func => "hexstr",   lsize => 1, limit => [0, 0]},
  ModemCapabilities   => {
    code   => 5,
    func   => "nested",
    lsize  => 1,
    limit  => [0, 0],
    nested => {
      BaselinePrivacySupport => {code => 6,  func => "uchar", lsize => 1, limit => [0, 1]},
      ConcatenationSupport   => {code => 1,  func => "uchar", lsize => 1, limit => [0, 1]},
      DCCSupport             => {code => 12, func => "uchar", lsize => 1, limit => [0, 1]},
      DownstreamSAIDSupport  => {code => 7,  func => "uchar", lsize => 1, limit => [0, 255]},
      FragmentationSupport   => {code => 3,  func => "uchar", lsize => 1, limit => [0, 1]},
      IGMPSupport            => {code => 5,  func => "uchar", lsize => 1, limit => [0, 1]},
      ModemDocsisVersion     => {code => 2,  func => "uchar", lsize => 1, limit => [0, 2]},
      PHSSupport             => {code => 4,  func => "uchar", lsize => 1, limit => [0, 1]},
      UpstreamSIDSupport     => {code => 8,  func => "uchar", lsize => 1, limit => [0, 255]},
    },
  },
  MtaConfigDelimiter => {code => 254, func => "uchar", lsize => 1, limit => [1, 255]},
  NetworkAccess      => {code => 3,   func => "uchar", lsize => 1, limit => [0, 1]},
  PHS                => {
    code   => 26,
    func   => "nested",
    lsize  => 1,
    limit  => [0, 0],
    nested => {
      PHSClassifierId   => {code => 2,  func => "ushort", lsize => 1, limit => [1, 65535]},
      PHSClassifierRef  => {code => 1,  func => "uchar",  lsize => 1, limit => [1, 255]},
      PHSField          => {code => 7,  func => "hexstr", lsize => 1, limit => [1, 255]},
      PHSIndex          => {code => 8,  func => "uchar",  lsize => 1, limit => [1, 255]},
      PHSMask           => {code => 9,  func => "hexstr", lsize => 1, limit => [1, 255]},
      PHSServiceFlowId  => {code => 4,  func => "uint",   lsize => 1, limit => [1, 4294967295]},
      PHSServiceFlowRef => {code => 3,  func => "ushort", lsize => 1, limit => [1, 65535]},
      PHSSize           => {code => 10, func => "uchar",  lsize => 1, limit => [1, 255]},
      PHSVerify         => {code => 11, func => "uchar",  lsize => 1, limit => [0, 1]},
    },
  },
  SnmpCpeAccessControl => {code => 55, func => "uchar",       lsize => 1, limit => [0, 1]},
  SnmpMibObject        => {code => 11, func => "snmp_object", lsize => 1, limit => [1, 255]},
  SnmpV3Kickstart      => {
    code   => 34,
    func   => "nested",
    lsize  => 1,
    limit  => [0, 0],
    nested => {
      SnmpV3MgrPublicNumber => {code => 2, func => "hexstr", lsize => 1, limit => [1, 514]},
      SnmpV3SecurityName    => {code => 1, func => "string", lsize => 1, limit => [1, 16]},
    },
  },
  SnmpV3TrapReceiver => {
    code   => 38,
    func   => "nested",
    lsize  => 1,
    limit  => [0, 0],
    nested => {
      SnmpV3TrapRxFilterOID    => {code => 6, func => "ushort", lsize => 1, limit => [1, 5]},
      SnmpV3TrapRxIP           => {code => 1, func => "ip",     lsize => 1, limit => [0, 0]},
      SnmpV3TrapRxPort         => {code => 2, func => "ushort", lsize => 1, limit => [0, 0]},
      SnmpV3TrapRxRetries      => {code => 5, func => "ushort", lsize => 1, limit => [0, 65535]},
      SnmpV3TrapRxSecurityName => {code => 7, func => "string", lsize => 1, limit => [1, 16]},
      SnmpV3TrapRxTimeout      => {code => 4, func => "ushort", lsize => 1, limit => [0, 65535]},
      SnmpV3TrapRxType         => {code => 3, func => "ushort", lsize => 1, limit => [1, 5]},
    },
  },
  SubMgmtControl    => {code => 35, func => "hexstr",      lsize => 1, limit => [3, 3]},
  SubMgmtCpeTable   => {code => 36, func => "hexstr",      lsize => 1, limit => [0, 0]},
  SubMgmtFilters    => {code => 37, func => "ushort_list", lsize => 1, limit => [4, 4]},
  SwUpgradeFilename => {code => 9,  func => "string",      lsize => 1, limit => [0, 0]},
  SwUpgradeServer   => {code => 21, func => "ip",          lsize => 1, limit => [0, 0]},
  TestMode          => {code => 40, func => "hexstr",      lsize => 1, limit => [0, 1]},
  TftpModemAddress  => {code => 20, func => "ip",          lsize => 1, limit => [0, 0]},
  TftpTimestamp     => {code => 19, func => "uint",        lsize => 1, limit => [0, 4294967295]},
  UpstreamChannelId => {code => 2,  func => "uchar",       lsize => 1, limit => [0, 255]},
  UsPacketClass     => {
    code   => 22,
    func   => "nested",
    lsize  => 1,
    limit  => [0, 0],
    nested => {
      ActivationState   => {code => 6, func => "uchar",  lsize => 1, limit => [0, 1]},
      ClassifierId      => {code => 2, func => "ushort", lsize => 1, limit => [1, 65535]},
      ClassifierRef     => {code => 1, func => "uchar",  lsize => 1, limit => [1, 255]},
      DscAction         => {code => 7, func => "uchar",  lsize => 1, limit => [0, 2]},
      IEEE802Classifier => {
        code   => 11,
        func   => "nested",
        lsize  => 1,
        limit  => [0, 0],
        nested => {
          UserPriority => {code => 1, func => "ushort", lsize => 1, limit => [0, 0]},
          VlanID       => {code => 2, func => "ushort", lsize => 1, limit => [0, 0]},
        },
      },
      IpPacketClassifier => {
        code   => 9,
        func   => "nested",
        lsize  => 1,
        limit  => [0, 0],
        nested => {
          DstPortEnd   => {code => 10, func => "ushort", lsize => 1, limit => [0, 65535]},
          DstPortStart => {code => 9,  func => "ushort", lsize => 1, limit => [0, 65535]},
          IpDstAddr    => {code => 5,  func => "ip",     lsize => 1, limit => [0, 0]},
          IpDstMask    => {code => 6,  func => "ip",     lsize => 1, limit => [0, 0]},
          IpProto      => {code => 2,  func => "ushort", lsize => 1, limit => [0, 257]},
          IpSrcAddr    => {code => 3,  func => "ip",     lsize => 1, limit => [0, 0]},
          IpSrcMask    => {code => 4,  func => "ip",     lsize => 1, limit => [0, 0]},
          IpTos        => {code => 1,  func => "hexstr", lsize => 1, limit => [0, 0]},
          SrcPortEnd   => {code => 8,  func => "ushort", lsize => 1, limit => [0, 65535]},
          SrcPortStart => {code => 7,  func => "ushort", lsize => 1, limit => [0, 65535]},
        }
      },
      LLCPacketClassifier => {
        code   => 10,
        func   => "nested",
        lsize  => 1,
        limit  => [0, 0],
        nested => {
          DstMacAddress => {code => 1, func => "ether",  lsize => 1, limit => [0, 0]},
          EtherType     => {code => 3, func => "hexstr", lsize => 1, limit => [0, 0]},
          SrcMacAddress => {code => 2, func => "ether",  lsize => 1, limit => [0, 0]},
        },
      },
      RulePriority   => {code => 5, func => "uchar",  lsize => 1, limit => [0, 255]},
      ServiceFlowId  => {code => 4, func => "uint",   lsize => 1, limit => [1, 4294967295]},
      ServiceFlowRef => {code => 3, func => "ushort", lsize => 1, limit => [1, 65535]},
    },
  },
  UsServiceFlow => {
    code   => 24,
    func   => "nested",
    lsize  => 1,
    limit  => [0, 0],
    nested => {
      ActQosParamsTimeout  => {code => 12, func => "ushort",  lsize => 1, limit => [0, 65535]},
      AdmQosParamsTimeout  => {code => 13, func => "ushort",  lsize => 1, limit => [0, 65535]},
      GrantsPerInterval    => {code => 22, func => "uchar",   lsize => 1, limit => [0, 127]},
      IpTosOverwrite       => {code => 23, func => "hexstr",  lsize => 1, limit => [0, 255]},
      MaxConcatenatedBurst => {code => 14, func => "ushort",  lsize => 1, limit => [0, 65535]},
      MaxRateSustained     => {code => 8,  func => "uint",    lsize => 1, limit => [0, 0]},
      MaxTrafficBurst      => {code => 9,  func => "uint",    lsize => 1, limit => [0, 0]},
      MinReservedRate      => {code => 10, func => "uint",    lsize => 1, limit => [0, 0]},
      MinResPacketSize     => {code => 11, func => "ushort",  lsize => 1, limit => [0, 65535]},
      NominalGrantInterval => {code => 20, func => "uint",    lsize => 1, limit => [0, 0]},
      NominalPollInterval  => {code => 17, func => "uint",    lsize => 1, limit => [0, 0]},
      QosParamSetType      => {code => 6,  func => "uchar",   lsize => 1, limit => [0, 255]},
      RequestOrTxPolicy    => {code => 16, func => "hexstr",  lsize => 1, limit => [0, 255]},
      SchedulingType       => {code => 15, func => "uchar",   lsize => 1, limit => [0, 6]},
      ServiceClassName     => {code => 4,  func => "stringz", lsize => 1, limit => [2, 16]},
      ToleratedGrantJitter => {code => 21, func => "uint",    lsize => 1, limit => [0, 0]},
      ToleratedPollJitter  => {code => 18, func => "uint",    lsize => 1, limit => [0, 0]},
      TrafficPriority      => {code => 7,  func => "uchar",   lsize => 1, limit => [0, 7]},
      UnsolicitedGrantSize => {code => 19, func => "ushort",  lsize => 1, limit => [0, 65535]},
      UsServiceFlowId      => {code => 2,  func => "uint",    lsize => 1, limit => [1, 4294967295]},
      UsServiceFlowRef     => {code => 1,  func => "ushort",  lsize => 1, limit => [1, 65535]},
      UsVendorSpecific     => {code => 43, func => "vendor",  lsize => 1, limit => [0, 0]},
    },
  },
  eRouter  => {
    code   => 202,
    func   => "nested",
    lsize  => 1,
    limit  => [0, 0],
    nested => {
      ManagementServer  => {
        code   => 2,
        func   => "nested",
        lsize  => 1,
        limit  => [0, 0],
        nested => {
          EnableCWMP                => {code => 1,  func => "uchar",  lsize => 1, limit => [0, 1]},
          URL                       => {code => 2,  func => "string", lsize => 1, limit => [0, 0]},
          Username                  => {code => 3,  func => "string", lsize => 1, limit => [0, 0]},
          Password                  => {code => 4,  func => "string", lsize => 1, limit => [0, 0]},
          ConnectionRequestUsername => {code => 5,  func => "string", lsize => 1, limit => [0, 0]},
          ConnectionRequestPassword => {code => 6,  func => "string", lsize => 1, limit => [0, 0]},
          ACSOverride               => {code => 7,  func => "uchar",  lsize => 1, limit => [0, 1]},
        },
      },
    },
  },
  VendorSpecific => {code => 43, func => "vendor", lsize => 1, limit => [0, 0],},
};

=head1 CLASS METHODS

=head2 add_symbol

Deprecated.

=head2 byte_size

Deprecated.

=head2 cmts_mic_codes

Deprecated.

=head2 dump_symbol_tree

Deprecated.

=head2 from_code

Deprecated.

=head2 from_id

Deprecated.

=head1 OBJECT METHODS

=head2 id

Deprecated.

=head2 code

Deprecated.

=head2 pcode

Deprecated.

=head2 func

Deprecated.

=head2 l_limit

Deprecated.

=head2 u_limit

Deprecated.

=head2 length

Deprecated.

=head2 siblings

Deprecated.

=cut

sub add_symbol {
  my $class  = shift;
  my $symbol = shift;
  my $key;

  # meant for internal usage...
  if (ref $symbol eq 'ARRAY') {
    $symbol = {map { $_ => shift @$symbol } @OBJECT_ATTRIBUTES};
  }

  $key = join '-', $symbol->{pcode}, $symbol->{code};

  $FROM_CODE{$key} = $symbol;
  push @{$FROM_ID{$symbol->{id}}}, $symbol;

  return 1;
}

sub dump_symbol_tree {
  my $class   = shift;
  my $pcode   = shift || 0;
  my $_seen   = shift || {};
  my $_indent = shift || 0;
  my @str;

  for my $symbol (sort { $a->{id} cmp $b->{id} } values %FROM_CODE) {
    next if ($_seen->{$symbol});
    next if ($symbol->{pcode} != $pcode);
    next if ($symbol->{code} == 0);
    my $width = 40 - $_indent * 2;

    $_seen->{$symbol} = 1;

    #               UpstreamChannelId   2   0  uchar    0  255    1
    push @str,
      sprintf(
      "%s%-${width}s %3s %3s  %-11s %10s %10s\n",
      ('  ' x $_indent),
      (map { defined $symbol->{$_} ? $symbol->{$_} : '' } @OBJECT_ATTRIBUTES),
      );

    if ($symbol->{func} =~ qr{nested|vendorspec}) {
      push @str, $class->dump_symbol_tree($symbol->{code}, $_seen, $_indent + 1);
    }
  }

  return @str if wantarray;
  return join '', map { (' ' x $pcode) . "$_\n" } @str;
}

sub from_id {
  my $class = shift;
  my $id    = shift;
  my @objs;

  return $class->_undef_symbol unless ($id);
  return $class->_undef_symbol unless ($FROM_ID{$id});

  @objs = map { bless \%{$_}, $class } @{$FROM_ID{$id}};

  $objs[0]->{siblings} = \@objs;

  return $objs[0];
}

sub from_code {
  my $class = shift;
  my $code  = shift || 0;
  my $pcode = shift || 0;

  return $class->_undef_symbol unless (defined $code and defined $pcode);
  return $class->_undef_symbol unless ($FROM_CODE{"$pcode-$code"});
  return bless $FROM_CODE{"$pcode-$code"}, $class;
}

sub _undef_symbol {
  my $class = shift;

  return bless {id => '', code => -1, pcode => -1, func => '', length => 0,}, $class;
}

sub cmts_mic_codes {
  qw/
    DownstreamFrequency  UpstreamChannelId
    NetworkAccess        ClassOfService
    BaselinePrivacy      VendorSpecific
    CmMic                MaxCPE
    TftpTimestamp        TftpModemAddress
    UsPacketClass        DsPacketClass
    UsServiceFlow        DsServiceFlow
    MaxClassifiers       GlobalPrivacyEnable
    PHS                  SubMgmtControl
    SubMgmtCpeTable      SubMgmtFilters
    TestMode
    /;
}

sub byte_size {
  return 2  if (lc $_[1] eq 'short int');
  return 4  if (lc $_[1] eq 'int');
  return 4  if (lc $_[1] eq 'long int');
  return 1  if (lc $_[1] eq 'char');
  return 4  if (lc $_[1] eq 'float');
  return 8  if (lc $_[1] eq 'double');
  return 12 if (lc $_[1] eq 'long double');
  return 16 if (lc $_[1] eq 'md5digest');
}

sub id       { $_[0]->{id} }
sub code     { $_[0]->{code} }
sub pcode    { $_[0]->{pcode} }
sub func     { $_[0]->{func} }
sub l_limit  { $_[0]->{l_limit} }
sub u_limit  { $_[0]->{u_limit} }
sub length   { $_[0]->{length} }
sub siblings { $_[0]->{siblings} }

sub TO_JSON {
  my ($class, $tree, $pcode, $seen) = @_;

  $pcode ||= 0;
  $tree  ||= {};
  $seen  ||= {};

  for my $symbol (sort { $a->{id} cmp $b->{id} } values %FROM_CODE) {
    next if $symbol->{code} == 0;
    next if $symbol->{pcode} != $pcode;
    next if $seen->{$symbol}++;

    my $current = $tree->{$symbol->{id}} = {%$symbol};

    if ($symbol->{func} =~ qr{nested|vendorspec}) {
      $current->{$symbol->{func}} = $class->TO_JSON({}, $symbol->{code}, $seen);
    }

    $current->{limit} = [@$symbol{qw( l_limit u_limit )}];
    delete $current->{$_} for qw( pcode id l_limit u_limit );
  }

  return $tree;
}

#==================================================================================
#     ID                     CODE PCODE   FUNC         L_LIMIT   H_LIMIT     LENGTH
#     identifier      docsis_code   pID   func         low_limit high_limit  length
#----------------------------------------------------------------------------------
__PACKAGE__->add_symbol($_)
  for (
  [qw( Pad                       0     0   nested       0         255         1 )],
  [qw( DownstreamFrequency       1     0   uint         88000000  860000000   1 )],
  [qw( UpstreamChannelId         2     0   uchar        0         255         1 )],
  [qw( CmMic                     6     0   mic          0         0           1 )],
  [qw( CmtsMic                   7     0   mic          0         0           1 )],
  [qw( NetworkAccess             3     0   uchar        0         1           1 )],
  [qw( ClassOfService            4     0   nested       0         0           1 )],
  [qw( ClassID                   1     4   uchar        1         16          1 )],
  [qw( MaxRateDown               2     4   uint         0         52000000    1 )],
  [qw( MaxRateUp                 3     4   uint         0         10000000    1 )],
  [qw( PriorityUp                4     4   uchar        0         7           1 )],
  [qw( GuaranteedUp              5     4   uint         0         10000000    1 )],
  [qw( MaxBurstUp                6     4   ushort       0         65535       1 )],
  [qw( PrivacyEnable             7     4   uchar        0         1           1 )],
  [qw( SwUpgradeFilename         9     0   string       0         0           1 )],
  [qw( SnmpWriteControl         10     0   nested       0         0           1 )],
  [qw( SnmpMibObject            11     0   snmp_object  1         255         1 )],
  [qw( CpeMacAddress            14     0   ether        0         0           1 )],
  [qw( BaselinePrivacy          17     0   nested       0         0           1 )],
  [qw( AuthTimeout               1    17   uint         1         30          1 )],
  [qw( ReAuthTimeout             2    17   uint         1         30          1 )],
  [qw( AuthGraceTime             3    17   uint         1         6047999     1 )],
  [qw( OperTimeout               4    17   uint         1         10          1 )],
  [qw( ReKeyTimeout              5    17   uint         1         10          1 )],
  [qw( TEKGraceTime              6    17   uint         1         302399      1 )],
  [qw( AuthRejectTimeout         7    17   uint         1         600         1 )],
  [qw( MaxCPE                   18     0   uchar        1         254         1 )],
  [qw( SwUpgradeServer          21     0   ip           0         0           1 )],

  # DOCSIS1 .1-2.0
  [qw( UsPacketClass            22     0   nested       0         0           1 )],
  [qw( ClassifierRef             1    22   uchar        1         255         1 )],
  [qw( ClassifierId              2    22   ushort       1         65535       1 )],
  [qw( ServiceFlowRef            3    22   ushort       1         65535       1 )],
  [qw( ServiceFlowId             4    22   uint         1         4294967295  1 )],
  [qw( RulePriority              5    22   uchar        0         255         1 )],
  [qw( ActivationState           6    22   uchar        0         1           1 )],
  [qw( DscAction                 7    22   uchar        0         2           1 )],
  [qw( IpPacketClassifier        9    22   nested       0         0           1 )],
  [qw( IpTos                     1     9   hexstr       0         0           1 )],
  [qw( IpProto                   2     9   ushort       0         257         1 )],
  [qw( IpSrcAddr                 3     9   ip           0         0           1 )],
  [qw( IpSrcMask                 4     9   ip           0         0           1 )],
  [qw( IpDstAddr                 5     9   ip           0         0           1 )],
  [qw( IpDstMask                 6     9   ip           0         0           1 )],
  [qw( SrcPortStart              7     9   ushort       0         65535       1 )],
  [qw( SrcPortEnd                8     9   ushort       0         65535       1 )],
  [qw( DstPortStart              9     9   ushort       0         65535       1 )],
  [qw( DstPortEnd               10     9   ushort       0         65535       1 )],
  [qw( LLCPacketClassifier      10    22   nested       0         0           1 )],
  [qw( DstMacAddress             1    10   ether        0         0           1 )],
  [qw( SrcMacAddress             2    10   ether        0         0           1 )],
  [qw( EtherType                 3    10   hexstr       0         0           1 )],
  [qw( IEEE802Classifier        11    22   nested       0         0           1 )],
  [qw( UserPriority              1    11   ushort       0         0           1 )],
  [qw( VlanID                    2    11   ushort       0         0           1 )],

  # TODO: Vendor Specific support in the IEEE802Classifier
  [qw( DsPacketClass            23     0   nested       0         0           1 )],
  [qw( ClassifierRef             1    23   uchar        1         255         1 )],
  [qw( ClassifierId              2    23   ushort       1         65535       1 )],
  [qw( ServiceFlowRef            3    23   ushort       1         65535       1 )],
  [qw( ServiceFlowId             4    23   uint         1         4294967295  1 )],
  [qw( RulePriority              5    23   uchar        0         255         1 )],
  [qw( ActivationState           6    23   uchar        0         1           1 )],
  [qw( DscAction                 7    23   uchar        0         2           1 )],
  [qw( IpPacketClassifier        9    23   nested       0         0           1 )],

  #[qw( IpTos                     1     9   hexstr       0         0           1 )], # already defined
  #[qw( IpProto                   2     9   ushort       0         257         1 )], # already defined
  #[qw( IpSrcAddr                 3     9   ip           0         0           1 )], # already defined
  #[qw( IpSrcMask                 4     9   ip           0         0           1 )], # already defined
  #[qw( IpDstAddr                 5     9   ip           0         0           1 )], # already defined
  #[qw( IpDstMask                 6     9   ip           0         0           1 )], # already defined
  #[qw( SrcPortStart              7     9   ushort       0         65535       1 )], # already defined
  #[qw( SrcPortEnd                8     9   ushort       0         65535       1 )], # already defined
  #[qw( DstPortStart              9     9   ushort       0         65535       1 )], # already defined
  #[qw( DstPortEnd               10     9   ushort       0         65535       1 )], # already defined
  [qw( LLCPacketClassifier      10    23   nested       0         0           1 )],

  #[qw( DstMacAddress             1    10   ether        0         0           1 )], # already defined
  #[qw( SrcMacAddress             2    10   ether        0         0           1 )], # already defined
  #[qw( EtherType                 3    10   hexstr       0         255         1 )], # already defined
  [qw( IEEE802Classifier        11    23   nested       0         0           1 )],

  #[qw( UserPriority              1    11   ushort       0         0           1 )], # already defined
  #[qw( VlanID                    2    11   ushort       0         0           1 )], # already defined

  # Upstream Service Flow
  [qw( UsServiceFlow            24     0   nested       0         0           1 )],
  [qw( UsServiceFlowRef          1    24   ushort       1         65535       1 )],
  [qw( UsServiceFlowId           2    24   uint         1         4294967295  1 )],
  [qw( ServiceClassName          4    24   stringz      2         16          1 )],
  [qw( QosParamSetType           6    24   uchar        0         255         1 )],
  [qw( TrafficPriority           7    24   uchar        0         7           1 )],
  [qw( MaxRateSustained          8    24   uint         0         0           1 )],
  [qw( MaxTrafficBurst           9    24   uint         0         0           1 )],
  [qw( MinReservedRate          10    24   uint         0         0           1 )],
  [qw( MinResPacketSize         11    24   ushort       0         65535       1 )],
  [qw( ActQosParamsTimeout      12    24   ushort       0         65535       1 )],
  [qw( AdmQosParamsTimeout      13    24   ushort       0         65535       1 )],
  [qw( UsVendorSpecific         43    24   vendorspec   0         0           1 )],

  # Upstream Service Flow Specific params
  [qw( MaxConcatenatedBurst     14    24   ushort       0         65535       1 )],
  [qw( SchedulingType           15    24   uchar        0         6           1 )],
  [qw( RequestOrTxPolicy        16    24   hexstr       0         255         1 )],
  [qw( NominalPollInterval      17    24   uint         0         0           1 )],
  [qw( ToleratedPollJitter      18    24   uint         0         0           1 )],
  [qw( UnsolicitedGrantSize     19    24   ushort       0         65535       1 )],
  [qw( NominalGrantInterval     20    24   uint         0         0           1 )],
  [qw( ToleratedGrantJitter     21    24   uint         0         0           1 )],
  [qw( GrantsPerInterval        22    24   uchar        0         127         1 )],
  [qw( IpTosOverwrite           23    24   hexstr       0         255         1 )],

  # Downstream Service Flow
  [qw( DsServiceFlow            25     0   nested       0         0           1 )],
  [qw( DsServiceFlowRef          1    25   ushort       1         65535       1 )],
  [qw( DsServiceFlowId           2    25   uint         1         4294967295  1 )],
  [qw( ServiceClassName          4    25   stringz      2         16          1 )],
  [qw( QosParamSetType           6    25   uchar        0         255         1 )],
  [qw( TrafficPriority           7    25   uchar        0         7           1 )],
  [qw( MaxRateSustained          8    25   uint         0         4294967295  1 )],
  [qw( MaxTrafficBurst           9    25   uint         0         4294967295  1 )],
  [qw( MinReservedRate          10    25   uint         0         4294967295  1 )],
  [qw( MinResPacketSize         11    25   ushort       0         65535       1 )],
  [qw( ActQosParamsTimeout      12    25   ushort       0         65535       1 )],
  [qw( AdmQosParamsTimeout      13    25   ushort       0         65535       1 )],
  [qw( DsVendorSpecific         43    25   vendorspec   0         0           1 )],

  # Downstream Service Flow Specific Params
  [qw( MaxDsLatency             14    25   uint         0         0           1 )],

  # Payload Header Suppression - Appendix C.2.2.8
  [qw( PHS                      26     0   nested       0         0           1 )],
  [qw( PHSClassifierRef          1    26   uchar        1         255         1 )],
  [qw( PHSClassifierId           2    26   ushort       1         65535       1 )],
  [qw( PHSServiceFlowRef         3    26   ushort       1         65535       1 )],
  [qw( PHSServiceFlowId          4    26   uint         1         4294967295  1 )],

  # Payload Header Suppression Rule - Appendix C.2.2.10
  [qw( PHSField                  7    26   hexstr       1         255         1 )],
  [qw( PHSIndex                  8    26   uchar        1         255         1 )],
  [qw( PHSMask                   9    26   hexstr       1         255         1 )],
  [qw( PHSSize                  10    26   uchar        1         255         1 )],
  [qw( PHSVerify                11    26   uchar        0         1           1 )],
  [qw( MaxClassifiers           28     0   ushort       0         0           1 )],
  [qw( GlobalPrivacyEnable      29     0   uchar        0         0           1 )],

  # BPI+ SubTLV  s
  [qw( SAMapWaitTimeout          8    17   uint         1         10          1 )],
  [qw( SAMapMaxRetries           9    17   uint         0         10          1 )],

  # ManufacturerCVC
  [qw( MfgCVCData               32     0   hexstr       0         0           1 )],

  # Vendor Specific
  [qw( VendorSpecific           43     0   vendorspec   0         0           1 )],
  [qw( VendorIdentifier          8    43   hexstr       3         3           1 )],

  # SNMPv3 Kickstart
  [qw( SnmpV3Kickstart          34     0   nested       0         0           1 )],

  # TODO: SP-RFI-v2.0 says the SecurityName is UTF8 encoded
  [qw( SnmpV3SecurityName        1    34   string       1         16          1 )],
  [qw( SnmpV3MgrPublicNumber     2    34   hexstr       1         514         1 )],

  # Snmpv3 Notification Receiver
  [qw( SnmpV3TrapReceiver       38     0   nested       0         0           1 )],
  [qw( SnmpV3TrapRxIP            1    38   ip           0         0           1 )],
  [qw( SnmpV3TrapRxPort          2    38   ushort       0         0           1 )],
  [qw( SnmpV3TrapRxType          3    38   ushort       1         5           1 )],
  [qw( SnmpV3TrapRxTimeout       4    38   ushort       0         65535       1 )],
  [qw( SnmpV3TrapRxRetries       5    38   ushort       0         65535       1 )],
  [qw( SnmpV3TrapRxFilterOID     6    38   ushort       1         5           1 )],
  [qw( SnmpV3TrapRxSecurityName  7    38   string       1         16          1 )],
  [qw( DocsisTwoEnable          39     0   uchar        0         1           1 )],

  # Modem Capabilities Encodings
  [qw( ModemCapabilities         5     0   nested       0         0           1 )],
  [qw( ConcatenationSupport      1     5   uchar        0         1           1 )],
  [qw( ModemDocsisVersion        2     5   uchar        0         2           1 )],
  [qw( FragmentationSupport      3     5   uchar        0         1           1 )],
  [qw( PHSSupport                4     5   uchar        0         1           1 )],
  [qw( IGMPSupport               5     5   uchar        0         1           1 )],
  [qw( BaselinePrivacySupport    6     5   uchar        0         1           1 )],
  [qw( DownstreamSAIDSupport     7     5   uchar        0         255         1 )],
  [qw( UpstreamSIDSupport        8     5   uchar        0         255         1 )],
  [qw( DCCSupport               12     5   uchar        0         1           1 )],
  [qw( SubMgmtControl           35     0   hexstr       3         3           1 )],
  [qw( SubMgmtCpeTable          36     0   hexstr       0         0           1 )],
  [qw( SubMgmtFilters           37     0   ushort_list  4         4           1 )],
  [qw( SnmpCpeAccessControl     55     0   uchar        0         1           1 )],
  [qw( SnmpMibObject            64     0   snmp_object  1         65535       2 )],
  [qw( TestMode                 40     0   hexstr       0         1           1 )],

  # PacketCable MTA Configuration File Delimiter
  [qw( MtaConfigDelimiter      254     0   uchar        1         255         1 )],
  [qw( DsChannelList            41     0   nested       1         255         1 )],
  [qw( SingleDsChannel           1    41   nested       1         255         1 )],
  [qw( SingleDsTimeout           1     1   ushort       0         65535       1 )],
  [qw( SingleDsFrequency         2     1   uint         0         4294967295  1 )],
  [qw( DsFreqRange               2    41   nested       1         255         1 )],
  [qw( DsFreqRangeTimeout        1     2   ushort       0         65535       1 )],
  [qw( DsFreqRangeStart          2     2   uint         0         4294967295  1 )],
  [qw( DsFreqRangeEnd            3     2   uint         0         4294967295  1 )],
  [qw( DsFreqRangeStepSize       4     2   uint         0         4294967295  1 )],
  [qw( DefaultScanTimeout        3    41   ushort       0         65535       1 )],
  [qw( TftpTimestamp            19     0   uint         0         4294967295  1 )],
  [qw( TftpModemAddress         20     0   ip           0         0           1 )],

  # eRouter
  [qw( eRouter                 202     0   nested       0         0           1 )],
  [qw( ManagementServer          2   202   nested       0         0           1 )],
  [qw( EnableCWMP                1     2   uchar        0         1           1 )],
  [qw( URL                       2     2   string       0         0           1 )],
  [qw( Username                  3     2   string       0         0           1 )],
  [qw( Password                  4     2   string       0         0           1 )],
  [qw( ConnectionRequestUsername 5     2   string       0         0           1 )],
  [qw( ConnectionRequestPassword 6     2   string       0         0           1 )],
  [qw( ACSOverride               7     2   uchar        0         1           1 )],

  # Generic TLV... we only use the limits  code and length dont matter
  [qw( GenericTLV              255     0   no_value     0         0           1 )],
  );

#-------------------------------------------------------------------------------------
#        ID                     CODE PCODE   FUNC         L_LIMIT   H_LIMIT     LENGTH
#=====================================================================================

=head1 AUTHOR

Jan Henning Thorsen - C<jhthorsen@cpan.org>

=cut

__PACKAGE__;
