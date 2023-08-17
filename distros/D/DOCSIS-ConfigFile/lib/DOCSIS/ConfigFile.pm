package DOCSIS::ConfigFile;
use strict;
use warnings;
use Carp qw(carp confess croak);

use constant CAN_TRANSLATE_OID => $ENV{DOCSIS_CAN_TRANSLATE_OID} // eval 'require SNMP;1' || 0;
use constant DEBUG             => $ENV{DOCSIS_CONFIGFILE_DEBUG}                           || 0;
use if DEBUG, 'Data::Dumper';

if (CAN_TRANSLATE_OID) {
  require File::Basename;
  require File::Spec;
  our $OID_DIR = File::Spec->rel2abs(
    File::Spec->catdir(File::Basename::dirname(__FILE__), 'ConfigFile', 'mibs'));
  warn "[DOCSIS] Adding OID directory $OID_DIR\n" if DEBUG;
  SNMP::addMibDirs($OID_DIR);
  SNMP::loadModules('ALL');
}

use Digest::MD5 ();
use Digest::HMAC_MD5;
use Digest::SHA;
use Exporter 'import';
use DOCSIS::ConfigFile::Decode;
use DOCSIS::ConfigFile::Encode;

our $VERSION = '1.01';
our @EXPORT_OK = qw(decode_docsis encode_docsis);
our ($DEPTH, $CONFIG_TREE, @CMTS_MIC) = (0, {});

sub decode_docsis {
  my $options = ref $_[-1] eq 'HASH' ? $_[-1] : {};
  my $bytes   = shift;
  my $current = $options->{blueprint} || $CONFIG_TREE;
  my $pos     = $options->{pos}       || 0;
  my $data    = {};
  my $end;

  if (ref $bytes eq 'SCALAR') {
    my ($file, $r) = ($$bytes, 0);
    $bytes = '';
    open my $BYTES, '<', $file or croak "Can't decode DOCSIS file $file: $!";
    while ($r = sysread $BYTES, my $buf, 131072, 0) { $bytes .= $buf }
    croak "Can't decode DOCSIS file $file: $!" unless defined $r;
    warn "[DOCSIS] Decode @{[length $bytes]} bytes from $file\n" if DEBUG;
  }

  local $DEPTH = $DEPTH + 1 if DEBUG;
  $end = $options->{end} || length $bytes;

  while ($pos < $end) {
    my $code = unpack 'C', substr $bytes, $pos++, 1 or next;    # next on $code=0
    my ($length, $t, $name, $syminfo, $value);

    for (keys %$current) {
      next unless $code == $current->{$_}{code};
      $name    = $_;
      $syminfo = $current->{$_};
      last;
    }

    unless ($name) {
      carp "[DOCSIS] Internal error: No syminfo defined for code=$code.";
      next;
    }

    unless ($syminfo->{lsize}) {
      warn sprintf "[DOCSIS]%sDecode %s type=%s (0x%02x), len=0\n", join('', (' ' x $DEPTH)),
        $name, $code, $code
        if DEBUG;
      next;
    }

    # Document: PKT-SP-PROV1.5-I03-070412
    # Chapter:  9.1 MTA Configuration File
    $t = $syminfo->{lsize} == 1 ? 'C' : 'n';    # 1=C, 2=n
    $length = unpack $t, substr $bytes, $pos, $syminfo->{lsize};
    $pos += $syminfo->{lsize};

    warn sprintf "[DOCSIS]%sDecode %s type=%s (0x%02x), len=%s, with %s()\n",
      join('', (' ' x $DEPTH)), $name, $code, $code, $length, $syminfo->{func} // 'unknown'
      if DEBUG;

    if ($syminfo->{nested}) {
      local @$options{qw(blueprint end pos)} = ($syminfo->{nested}, $length + $pos, $pos);
      $value = decode_docsis($bytes, $options);
    }
    elsif (my $f = DOCSIS::ConfigFile::Decode->can($syminfo->{func})) {
      $value = $f->(substr $bytes, $pos, $length);
      $value = {oid => @$value{qw(oid type value)}} if $name eq 'SnmpMibObject';
    }
    else {
      confess
        qq(Can't locate object method "$syminfo->{func}" via package "DOCSIS::ConfigFile::Decode");
    }

    $pos += $length;

    if (!exists $data->{$name}) {
      $data->{$name} = $value;
    }
    elsif (ref $data->{$name} eq 'ARRAY') {
      push @{$data->{$name}}, $value;
    }
    else {
      $data->{$name} = [$data->{$name}, $value];
    }
  }

  return $data;
}

sub encode_docsis {
  my ($data, $options) = @_;
  my $current = $options->{blueprint} || $CONFIG_TREE;
  my $mic     = {};
  my $bytes   = '';

  local $options->{depth} = ($options->{depth} || 0) + 1;
  local $DEPTH = $options->{depth} if DEBUG;

  if ($options->{depth} == 1 and defined $options->{mta_algorithm}) {
    delete $data->{MtaConfigDelimiter};
    $bytes .= encode_docsis({MtaConfigDelimiter => 1}, {depth => 1});
  }

  for my $name (sort { $current->{$a}{code} <=> $current->{$b}{code} } keys %$current) {
    next unless defined $data->{$name};
    my $syminfo = $current->{$name};
    my ($type, $length, $value);

    for my $item (_to_list($data->{$name}, $syminfo)) {
      if ($syminfo->{nested}) {
        warn "[DOCSIS]@{[' 'x$DEPTH]}Encode $name with encode_docsis\n" if DEBUG;
        local @$options{qw(blueprint)} = ($current->{$name}{nested});
        $value = encode_docsis($item, $options);
      }
      elsif (my $f = DOCSIS::ConfigFile::Encode->can($syminfo->{func})) {
        warn "[DOCSIS]@{[' 'x$DEPTH]}Encode $name with $syminfo->{func}\n" if DEBUG;
        if ($syminfo->{func} =~ /_list$/) {
          $value = pack 'C*', $f->({value => _validate($item, $syminfo)});
        }
        elsif ($name eq 'SnmpMibObject') {
          my @k = qw(type value);
          local $item->{oid} = $item->{oid};
          $value = pack 'C*',
            $f->({value => {oid => delete $item->{oid}, map { shift(@k), $_ } %$item}});
        }
        else {
          local $syminfo->{name} = $name;
          $value = pack 'C*', $f->({value => _validate($item, $syminfo)});
        }
      }
      else {
        confess
          qq(Can't locate object method "$syminfo->{func}" via package "DOCSIS::ConfigFile::Encode");
      }

      {
        use warnings FATAL => 'all';
        $type   = pack 'C', $syminfo->{code};
        $length = $syminfo->{lsize} == 2 ? pack('n', length $value) : pack('C', length $value);
      }

      $mic->{$name} = "$type$length$value";
      $bytes .= $mic->{$name};
    }
  }

  return $bytes                     if $options->{depth} != 1;
  return _mta_eof($bytes, $options) if defined $options->{mta_algorithm};
  return _cm_eof($bytes, $mic, $options);
}

sub _cm_eof {
  my $mic      = $_[1];
  my $options  = $_[2];
  my $cmts_mic = '';
  my $pads     = 4 - (1 + length $_[0]) % 4;
  my $eod_pad;

  $mic->{CmMic} = pack('C*', 6, 16) . Digest::MD5::md5($_[0]);

  $cmts_mic .= $mic->{$_} || '' for @CMTS_MIC;
  $cmts_mic
    = pack('C*', 7, 16) . Digest::HMAC_MD5::hmac_md5($cmts_mic, $options->{shared_secret} || '');
  $eod_pad = pack('C', 255) . ("\0" x $pads);

  return $_[0] . $mic->{CmMic} . $cmts_mic . $eod_pad;
}

sub _mta_eof {
  my $mta_algorithm = $_[1]->{mta_algorithm} || '';
  my $hash          = '';

  if ($mta_algorithm) {
    croak "mta_algorithm must be empty string, md5 or sha1."
      unless $mta_algorithm =~ /^(md5|sha1)$/;
    $hash = $mta_algorithm eq 'md5' ? Digest::MD5::md5_hex($_[0]) : Digest::SHA::sha1_hex($_[0]);
    $hash
      = encode_docsis(
      {SnmpMibObject => {oid => '1.3.6.1.4.1.4491.2.2.1.1.2.7.0', STRING => "0x$hash"}},
      {depth         => 1});
  }

  return $hash . $_[0] . encode_docsis({MtaConfigDelimiter => 255}, {depth => 1});
}

sub _to_list {
  return $_[0]    if $_[1]->{func} =~ /_list$/;
  return @{$_[0]} if ref $_[0] eq 'ARRAY';
  return $_[0];
}

# _validate($value, $syminfo);
sub _validate {
  if ($_[1]->{limit}[1]) {
    if ($_[0] =~ /^-?\d+$/) {
      croak "[DOCSIS] $_[1]->{name} holds a too high value. ($_[0])" if $_[1]->{limit}[1] < $_[0];
      croak "[DOCSIS] $_[1]->{name} holds a too low value. ($_[0])"  if $_[0] < $_[1]->{limit}[0];
    }
    else {
      my $length = ref $_[0] eq 'ARRAY' ? @{$_[0]} : length $_[0];
      croak "[DOCSIS] $_[1]->{name} is too long. ($_[0])"  if $_[1]->{limit}[1] < $length;
      croak "[DOCSIS] $_[1]->{name} is too short. ($_[0])" if $length < $_[1]->{limit}[0];
    }
  }
  return $_[0];
}

@CMTS_MIC = qw(
  DownstreamFrequency UpstreamChannelId NetworkAccess
  ClassOfService      BaselinePrivacy   VendorSpecific
  CmMic               MaxCPE            TftpTimestamp
  TftpModemAddress    UsPacketClass     DsPacketClass
  UsServiceFlow       DsServiceFlow     MaxClassifiers
  GlobalPrivacyEnable PHS               SubMgmtControl
  SubMgmtCpeTable     SubMgmtFilters    TestMode
);

$CONFIG_TREE = {
  BaselinePrivacy => {
    code   => 17,
    func   => 'nested',
    lsize  => 1,
    limit  => [0, 0],
    nested => {
      AuthGraceTime     => {code => 3, func => 'uint', lsize => 1, limit => [1, 6047999]},
      AuthRejectTimeout => {code => 7, func => 'uint', lsize => 1, limit => [1, 600]},
      AuthTimeout       => {code => 1, func => 'uint', lsize => 1, limit => [1, 30]},
      OperTimeout       => {code => 4, func => 'uint', lsize => 1, limit => [1, 10]},
      ReAuthTimeout     => {code => 2, func => 'uint', lsize => 1, limit => [1, 30]},
      ReKeyTimeout      => {code => 5, func => 'uint', lsize => 1, limit => [1, 10]},
      SAMapMaxRetries   => {code => 9, func => 'uint', lsize => 1, limit => [0, 10]},
      SAMapWaitTimeout  => {code => 8, func => 'uint', lsize => 1, limit => [1, 10]},
      TEKGraceTime      => {code => 6, func => 'uint', lsize => 1, limit => [1, 302399]},
    },
  },
  ClassOfService => {
    code   => 4,
    func   => 'nested',
    lsize  => 1,
    limit  => [0, 0],
    nested => {
      ClassID       => {code => 1, func => 'uchar',  lsize => 1, limit => [1, 16]},
      GuaranteedUp  => {code => 5, func => 'uint',   lsize => 1, limit => [0, 10000000]},
      MaxBurstUp    => {code => 6, func => 'ushort', lsize => 1, limit => [0, 65535]},
      MaxRateDown   => {code => 2, func => 'uint',   lsize => 1, limit => [0, 52000000]},
      MaxRateUp     => {code => 3, func => 'uint',   lsize => 1, limit => [0, 10000000]},
      PriorityUp    => {code => 4, func => 'uchar',  lsize => 1, limit => [0, 7]},
      PrivacyEnable => {code => 7, func => 'uchar',  lsize => 1, limit => [0, 1]},
    },
  },
  CmMic               => {code => 6,  func => 'mic',   lsize => 1, limit => [0,        0]},
  CmtsMic             => {code => 7,  func => 'mic',   lsize => 1, limit => [0,        0]},
  CpeMacAddress       => {code => 14, func => 'ether', lsize => 1, limit => [0,        0]},
  DocsisTwoEnable     => {code => 39, func => 'uchar', lsize => 1, limit => [0,        1]},
  DownstreamFrequency => {code => 1,  func => 'uint',  lsize => 1, limit => [88000000, 860000000]},
  DsChannelList       => {
    code   => 41,
    func   => 'nested',
    lsize  => 1,
    limit  => [1, 255],
    nested => {
      DefaultScanTimeout => {code => 3, func => 'ushort', lsize => 1, limit => [0, 65535]},
      DsFreqRange        => {
        code   => 2,
        func   => 'nested',
        lsize  => 1,
        limit  => [1, 255],
        nested => {
          DsFreqRangeEnd      => {code => 3, func => 'uint', lsize => 1, limit => [0, 4294967295]},
          DsFreqRangeStart    => {code => 2, func => 'uint', lsize => 1, limit => [0, 4294967295]},
          DsFreqRangeStepSize => {code => 4, func => 'uint', lsize => 1, limit => [0, 4294967295]},
          DsFreqRangeTimeout  => {code => 1, func => 'ushort', lsize => 1, limit => [0, 65535]},
        },
      },
      SingleDsChannel => {
        code   => 1,
        func   => 'nested',
        lsize  => 1,
        limit  => [1, 255],
        nested => {
          SingleDsFrequency => {code => 2, func => 'uint',   lsize => 1, limit => [0, 4294967295]},
          SingleDsTimeout   => {code => 1, func => 'ushort', lsize => 1, limit => [0, 65535]},
        },
      },
    },
  },
  DsPacketClass => {
    code   => 23,
    func   => 'nested',
    lsize  => 1,
    limit  => [0, 0],
    nested => {
      ActivationState   => {code => 6, func => 'uchar',  lsize => 1, limit => [0, 1]},
      ClassifierId      => {code => 2, func => 'ushort', lsize => 1, limit => [1, 65535]},
      ClassifierRef     => {code => 1, func => 'uchar',  lsize => 1, limit => [1, 255]},
      DscAction         => {code => 7, func => 'uchar',  lsize => 1, limit => [0, 2]},
      IEEE802Classifier => {
        code   => 11,
        func   => 'nested',
        lsize  => 1,
        limit  => [0, 0],
        nested => {
          UserPriority => {code => 1, func => 'ushort', lsize => 1, limit => [0, 0]},
          VlanID       => {code => 2, func => 'ushort', lsize => 1, limit => [0, 0]},
        },
      },
      IpPacketClassifier => {
        code   => 9,
        func   => 'nested',
        lsize  => 1,
        limit  => [0, 0],
        nested => {
          DstPortEnd   => {code => 10, func => 'ushort', lsize => 1, limit => [0, 65535]},
          DstPortStart => {code => 9,  func => 'ushort', lsize => 1, limit => [0, 65535]},
          IpDstAddr    => {code => 5,  func => 'ip',     lsize => 1, limit => [0, 0]},
          IpDstMask    => {code => 6,  func => 'ip',     lsize => 1, limit => [0, 0]},
          IpProto      => {code => 2,  func => 'ushort', lsize => 1, limit => [0, 257]},
          IpSrcAddr    => {code => 3,  func => 'ip',     lsize => 1, limit => [0, 0]},
          IpSrcMask    => {code => 4,  func => 'ip',     lsize => 1, limit => [0, 0]},
          IpTos        => {code => 1,  func => 'hexstr', lsize => 1, limit => [0, 0]},
          SrcPortEnd   => {code => 8,  func => 'ushort', lsize => 1, limit => [0, 65535]},
          SrcPortStart => {code => 7,  func => 'ushort', lsize => 1, limit => [0, 65535]},
        },
      },
      LLCPacketClassifier => {
        code   => 10,
        func   => 'nested',
        lsize  => 1,
        limit  => [0, 0],
        nested => {
          DstMacAddress => {code => 1, func => 'ether',  lsize => 1, limit => [0, 0]},
          EtherType     => {code => 3, func => 'hexstr', lsize => 1, limit => [0, 0]},
          SrcMacAddress => {code => 2, func => 'ether',  lsize => 1, limit => [0, 0]},
        },
      },
      RulePriority   => {code => 5, func => 'uchar',  lsize => 1, limit => [0, 255]},
      ServiceFlowId  => {code => 4, func => 'uint',   lsize => 1, limit => [1, 4294967295]},
      ServiceFlowRef => {code => 3, func => 'ushort', lsize => 1, limit => [1, 65535]},
    },
  },
  DsServiceFlow => {
    code   => 25,
    func   => 'nested',
    lsize  => 1,
    limit  => [0, 0],
    nested => {
      ActQosParamsTimeout => {code => 12, func => 'ushort',  lsize => 1, limit => [0, 65535]},
      AdmQosParamsTimeout => {code => 13, func => 'ushort',  lsize => 1, limit => [0, 65535]},
      DsServiceFlowId     => {code => 2,  func => 'uint',    lsize => 1, limit => [1, 4294967295]},
      DsServiceFlowRef    => {code => 1,  func => 'ushort',  lsize => 1, limit => [1, 65535]},
      DsVendorSpecific    => {code => 43, func => 'vendor',  lsize => 1, limit => [0, 0]},
      MaxDsLatency        => {code => 14, func => 'uint',    lsize => 1, limit => [0, 0]},
      MaxRateSustained    => {code => 8,  func => 'uint',    lsize => 1, limit => [0, 4294967295]},
      MaxTrafficBurst     => {code => 9,  func => 'uint',    lsize => 1, limit => [0, 4294967295]},
      MinReservedRate     => {code => 10, func => 'uint',    lsize => 1, limit => [0, 4294967295]},
      MinResPacketSize    => {code => 11, func => 'ushort',  lsize => 1, limit => [0, 65535]},
      QosParamSetType     => {code => 6,  func => 'uchar',   lsize => 1, limit => [0, 255]},
      ServiceClassName    => {code => 4,  func => 'stringz', lsize => 1, limit => [2, 16]},
      TrafficPriority     => {code => 7,  func => 'uchar',   lsize => 1, limit => [0, 7]},
    },
  },
  GenericTLV          => {code => 255, func => 'no_value', lsize => 0, limit => [0, 0]},
  GlobalPrivacyEnable => {code => 29,  func => 'uchar',    lsize => 1, limit => [0, 0]},
  MaxClassifiers      => {code => 28,  func => 'ushort',   lsize => 1, limit => [0, 0]},
  MaxCPE              => {code => 18,  func => 'uchar',    lsize => 1, limit => [1, 254]},
  MfgCVCData          => {code => 32,  func => 'hexstr',   lsize => 1, limit => [0, 0]},
  ModemCapabilities   => {
    code   => 5,
    func   => 'nested',
    lsize  => 1,
    limit  => [0, 0],
    nested => {
      BaselinePrivacySupport => {code => 6,  func => 'uchar', lsize => 1, limit => [0, 1]},
      ConcatenationSupport   => {code => 1,  func => 'uchar', lsize => 1, limit => [0, 1]},
      DCCSupport             => {code => 12, func => 'uchar', lsize => 1, limit => [0, 1]},
      DownstreamSAIDSupport  => {code => 7,  func => 'uchar', lsize => 1, limit => [0, 255]},
      FragmentationSupport   => {code => 3,  func => 'uchar', lsize => 1, limit => [0, 1]},
      IGMPSupport            => {code => 5,  func => 'uchar', lsize => 1, limit => [0, 1]},
      ModemDocsisVersion     => {code => 2,  func => 'uchar', lsize => 1, limit => [0, 2]},
      PHSSupport             => {code => 4,  func => 'uchar', lsize => 1, limit => [0, 1]},
      UpstreamSIDSupport     => {code => 8,  func => 'uchar', lsize => 1, limit => [0, 255]},
    },
  },
  MtaConfigDelimiter => {code => 254, func => 'uchar', lsize => 1, limit => [1, 255]},
  NetworkAccess      => {code => 3,   func => 'uchar', lsize => 1, limit => [0, 1]},
  PHS                => {
    code   => 26,
    func   => 'nested',
    lsize  => 1,
    limit  => [0, 0],
    nested => {
      PHSClassifierId   => {code => 2,  func => 'ushort', lsize => 1, limit => [1, 65535]},
      PHSClassifierRef  => {code => 1,  func => 'uchar',  lsize => 1, limit => [1, 255]},
      PHSField          => {code => 7,  func => 'hexstr', lsize => 1, limit => [1, 255]},
      PHSIndex          => {code => 8,  func => 'uchar',  lsize => 1, limit => [1, 255]},
      PHSMask           => {code => 9,  func => 'hexstr', lsize => 1, limit => [1, 255]},
      PHSServiceFlowId  => {code => 4,  func => 'uint',   lsize => 1, limit => [1, 4294967295]},
      PHSServiceFlowRef => {code => 3,  func => 'ushort', lsize => 1, limit => [1, 65535]},
      PHSSize           => {code => 10, func => 'uchar',  lsize => 1, limit => [1, 255]},
      PHSVerify         => {code => 11, func => 'uchar',  lsize => 1, limit => [0, 1]},
    },
  },
  SnmpCpeAccessControl => {code => 55, func => 'uchar',       lsize => 1, limit => [0, 1]},
  SnmpMibObject        => {code => 11, func => 'snmp_object', lsize => 1, limit => [1, 255]},
  SnmpV3Kickstart      => {
    code   => 34,
    func   => 'nested',
    lsize  => 1,
    limit  => [0, 0],
    nested => {
      SnmpV3MgrPublicNumber => {code => 2, func => 'hexstr', lsize => 1, limit => [1, 514]},
      SnmpV3SecurityName    => {code => 1, func => 'string', lsize => 1, limit => [1, 16]},
    },
  },
  SnmpV3TrapReceiver => {
    code   => 38,
    func   => 'nested',
    lsize  => 1,
    limit  => [0, 0],
    nested => {
      SnmpV3TrapRxFilterOID    => {code => 6, func => 'ushort', lsize => 1, limit => [1, 5]},
      SnmpV3TrapRxIP           => {code => 1, func => 'ip',     lsize => 1, limit => [0, 0]},
      SnmpV3TrapRxPort         => {code => 2, func => 'ushort', lsize => 1, limit => [0, 0]},
      SnmpV3TrapRxRetries      => {code => 5, func => 'ushort', lsize => 1, limit => [0, 65535]},
      SnmpV3TrapRxSecurityName => {code => 7, func => 'string', lsize => 1, limit => [1, 16]},
      SnmpV3TrapRxTimeout      => {code => 4, func => 'ushort', lsize => 1, limit => [0, 65535]},
      SnmpV3TrapRxType         => {code => 3, func => 'ushort', lsize => 1, limit => [1, 5]},
    },
  },
  SubMgmtControl    => {code => 35, func => 'hexstr',      lsize => 1, limit => [3, 3]},
  SubMgmtCpeTable   => {code => 36, func => 'hexstr',      lsize => 1, limit => [0, 0]},
  SubMgmtFilters    => {code => 37, func => 'ushort_list', lsize => 1, limit => [0, 20]},
  SwUpgradeFilename => {code => 9,  func => 'string',      lsize => 1, limit => [0, 0]},
  SwUpgradeServer   => {code => 21, func => 'ip',          lsize => 1, limit => [0, 0]},
  TestMode          => {code => 40, func => 'hexstr',      lsize => 1, limit => [0, 1]},
  TftpModemAddress  => {code => 20, func => 'ip',          lsize => 1, limit => [0, 0]},
  TftpTimestamp     => {code => 19, func => 'uint',        lsize => 1, limit => [0, 4294967295]},
  UpstreamChannelId => {code => 2,  func => 'uchar',       lsize => 1, limit => [0, 255]},
  UsPacketClass     => {
    code   => 22,
    func   => 'nested',
    lsize  => 1,
    limit  => [0, 0],
    nested => {
      ActivationState   => {code => 6, func => 'uchar',  lsize => 1, limit => [0, 1]},
      ClassifierId      => {code => 2, func => 'ushort', lsize => 1, limit => [1, 65535]},
      ClassifierRef     => {code => 1, func => 'uchar',  lsize => 1, limit => [1, 255]},
      DscAction         => {code => 7, func => 'uchar',  lsize => 1, limit => [0, 2]},
      IEEE802Classifier => {
        code   => 11,
        func   => 'nested',
        lsize  => 1,
        limit  => [0, 0],
        nested => {
          UserPriority => {code => 1, func => 'ushort', lsize => 1, limit => [0, 0]},
          VlanID       => {code => 2, func => 'ushort', lsize => 1, limit => [0, 0]},
        },
      },
      IpPacketClassifier => {
        code   => 9,
        func   => 'nested',
        lsize  => 1,
        limit  => [0, 0],
        nested => {
          DstPortEnd   => {code => 10, func => 'ushort', lsize => 1, limit => [0, 65535]},
          DstPortStart => {code => 9,  func => 'ushort', lsize => 1, limit => [0, 65535]},
          IpDstAddr    => {code => 5,  func => 'ip',     lsize => 1, limit => [0, 0]},
          IpDstMask    => {code => 6,  func => 'ip',     lsize => 1, limit => [0, 0]},
          IpProto      => {code => 2,  func => 'ushort', lsize => 1, limit => [0, 257]},
          IpSrcAddr    => {code => 3,  func => 'ip',     lsize => 1, limit => [0, 0]},
          IpSrcMask    => {code => 4,  func => 'ip',     lsize => 1, limit => [0, 0]},
          IpTos        => {code => 1,  func => 'hexstr', lsize => 1, limit => [0, 0]},
          SrcPortEnd   => {code => 8,  func => 'ushort', lsize => 1, limit => [0, 65535]},
          SrcPortStart => {code => 7,  func => 'ushort', lsize => 1, limit => [0, 65535]},
        }
      },
      LLCPacketClassifier => {
        code   => 10,
        func   => 'nested',
        lsize  => 1,
        limit  => [0, 0],
        nested => {
          DstMacAddress => {code => 1, func => 'ether',  lsize => 1, limit => [0, 0]},
          EtherType     => {code => 3, func => 'hexstr', lsize => 1, limit => [0, 0]},
          SrcMacAddress => {code => 2, func => 'ether',  lsize => 1, limit => [0, 0]},
        },
      },
      RulePriority   => {code => 5, func => 'uchar',  lsize => 1, limit => [0, 255]},
      ServiceFlowId  => {code => 4, func => 'uint',   lsize => 1, limit => [1, 4294967295]},
      ServiceFlowRef => {code => 3, func => 'ushort', lsize => 1, limit => [1, 65535]},
    },
  },
  UsServiceFlow => {
    code   => 24,
    func   => 'nested',
    lsize  => 1,
    limit  => [0, 0],
    nested => {
      ActQosParamsTimeout  => {code => 12, func => 'ushort',  lsize => 1, limit => [0, 65535]},
      AdmQosParamsTimeout  => {code => 13, func => 'ushort',  lsize => 1, limit => [0, 65535]},
      GrantsPerInterval    => {code => 22, func => 'uchar',   lsize => 1, limit => [0, 127]},
      IpTosOverwrite       => {code => 23, func => 'hexstr',  lsize => 1, limit => [0, 255]},
      MaxConcatenatedBurst => {code => 14, func => 'ushort',  lsize => 1, limit => [0, 65535]},
      MaxRateSustained     => {code => 8,  func => 'uint',    lsize => 1, limit => [0, 0]},
      MaxTrafficBurst      => {code => 9,  func => 'uint',    lsize => 1, limit => [0, 0]},
      MinReservedRate      => {code => 10, func => 'uint',    lsize => 1, limit => [0, 0]},
      MinResPacketSize     => {code => 11, func => 'ushort',  lsize => 1, limit => [0, 65535]},
      NominalGrantInterval => {code => 20, func => 'uint',    lsize => 1, limit => [0, 0]},
      NominalPollInterval  => {code => 17, func => 'uint',    lsize => 1, limit => [0, 0]},
      QosParamSetType      => {code => 6,  func => 'uchar',   lsize => 1, limit => [0, 255]},
      RequestOrTxPolicy    => {code => 16, func => 'hexstr',  lsize => 1, limit => [0, 255]},
      SchedulingType       => {code => 15, func => 'uchar',   lsize => 1, limit => [0, 6]},
      ServiceClassName     => {code => 4,  func => 'stringz', lsize => 1, limit => [2, 16]},
      ToleratedGrantJitter => {code => 21, func => 'uint',    lsize => 1, limit => [0, 0]},
      ToleratedPollJitter  => {code => 18, func => 'uint',    lsize => 1, limit => [0, 0]},
      TrafficPriority      => {code => 7,  func => 'uchar',   lsize => 1, limit => [0, 7]},
      UnsolicitedGrantSize => {code => 19, func => 'ushort',  lsize => 1, limit => [0, 65535]},
      UsServiceFlowId      => {code => 2,  func => 'uint',    lsize => 1, limit => [1, 4294967295]},
      UsServiceFlowRef     => {code => 1,  func => 'ushort',  lsize => 1, limit => [1, 65535]},
      UsVendorSpecific     => {code => 43, func => 'vendor',  lsize => 1, limit => [0, 0]},
    },
  },
  eRouter => {
    code   => 202,
    func   => 'nested',
    lsize  => 1,
    limit  => [0, 0],
    nested => {
      InitializationMode => {code => 1, func => 'uchar', lsize => 1, limit => [0, 3]},
      ManagementServer   => {
        code   => 2,
        func   => 'nested',
        lsize  => 1,
        limit  => [0, 0],
        nested => {
          EnableCWMP                => {code => 1, func => 'uchar',  lsize => 1, limit => [0, 1]},
          URL                       => {code => 2, func => 'string', lsize => 1, limit => [0, 0]},
          Username                  => {code => 3, func => 'string', lsize => 1, limit => [0, 0]},
          Password                  => {code => 4, func => 'string', lsize => 1, limit => [0, 0]},
          ConnectionRequestUsername => {code => 5, func => 'string', lsize => 1, limit => [0, 0]},
          ConnectionRequestPassword => {code => 6, func => 'string', lsize => 1, limit => [0, 0]},
          ACSOverride               => {code => 7, func => 'uchar',  lsize => 1, limit => [0, 1]},
        },
      },
      InitializationModeOverride => {code => 3, func => 'uchar', lsize => 1, limit => [0, 1]},
    },
  },
  VendorSpecific => {code => 43, func => 'vendor', lsize => 1, limit => [0, 0]},
};

=encoding utf8

=head1 NAME

DOCSIS::ConfigFile - Decodes and encodes DOCSIS config files

=head1 DESCRIPTION

L<DOCSIS::ConfigFile> is a class which provides functionality to decode and
encode L<DOCSIS|http://www.cablelabs.com> (Data over Cable Service Interface
Specifications) config files.

This module is used as a layer between any human readable data and
the binary structure.

The files are usually served using a L<TFTP server|Mojo::TFTPd>, after a
L<cable modem|http://en.wikipedia.org/wiki/Cable_modem> or MTA (Multimedia
Terminal Adapter) has recevied an IP address from a L<DHCP|Net::ISC::DHCPd>
server. These files are L<binary encode|DOCSIS::ConfigFile::Encode> using a
variety of functions, but all the data in the file are constructed by TLVs
(type-length-value) blocks. These can be nested and concatenated.

See the source code or L<https://thorsen.pm/docsisious> for list of
supported parameters.

=head1 SYNOPSIS

  use DOCSIS::ConfigFile qw(encode_docsis decode_docsis);

  $data = decode_docsis $bytes;
  $bytes = encode_docsis({
    GlobalPrivacyEnable => 1,
    MaxCPE              => 2,
    NetworkAccess       => 1,
    BaselinePrivacy     => {
      AuthTimeout       => 10,
      ReAuthTimeout     => 10,
      AuthGraceTime     => 600,
      OperTimeout       => 1,
      ReKeyTimeout      => 1,
      TEKGraceTime      => 600,
      AuthRejectTimeout => 60,
      SAMapWaitTimeout  => 1,
      SAMapMaxRetries   => 4
    },
    SnmpMibObject => [
      {oid => "1.3.6.1.4.1.1.77.1.6.1.1.6.2",    INTEGER => 1},
      {oid => "1.3.6.1.4.1.1429.77.1.6.1.1.6.2", STRING  => "bootfile.bin"}
    ],
    VendorSpecific => {id => "0x0011ee", options => [30 => "0xff", 31 => "0x00", 32 => "0x28"]}
  });

=head1 OPTIONAL MODULE

You can install the L<SNMP.pm|SNMP> module to translate between SNMP
OID formats. With the module installed, you can define the C<SnmpMibObject>
like the example below, instead of using numeric OIDs:

  encode_docsis({
    SnmpMibObject => [
      {oid => "docsDevNmAccessIp.1",     IPADDRESS => "10.0.0.1"},
      {oid => "docsDevNmAccessIpMask.1", IPADDRESS => "255.255.255.255"},
    ]
  });

=head1 WEB APPLICATION

There is an example web application bundled with this distribution called
"Docsisious". To run this application, you need to install L<Mojolicious> and
L<YAML::XS>:

  $ curl -L https://cpanmin.us | perl - -M https://cpan.metacpan.org DOCSIS::ConfigFile Mojolicious;

After installing the modules above, you can run the web app like this:

  $ docsisious --listen http://*:8000;

And then open your favorite browser at L<http://localhost:8000>. To see a live
demo, you can visit L<https://thorsen.pm/docsisious>.

=head1 FUNCTIONS

=head2 decode_docsis

  $data = decode_docsis($byte_string);
  $data = decode_docsis(\$path_to_file);

Used to decode a DOCSIS config file into a data structure. The output
C<$data> can be used as input to L</encode_docsis>. Note: C<$data>
will only contain array-refs if the DOCSIS parameter occur more than
once.

=head2 encode_docsis

  $byte_string = encode_docsis(\%data, \%args);

Used to encode a data structure into a DOCSIS config file. Each of the keys
in C<$data> can either hold a hash- or array-ref. An array-ref is used if
the same DOCSIS parameter occur multiple times. These two formats will result
in the same C<$byte_string>:

  # Only one SnmpMibObject
  encode_docsis({
    SnmpMibObject => {
      oid => "1.3.6.1.4.1.1429.77.1.6.1.1.6.2", STRING => "bootfile.bin"
    }
  })

  # Allow one or more SnmpMibObjects
  encode_docsis({
    SnmpMibObject => [
      {oid => "1.3.6.1.4.1.1429.77.1.6.1.1.6.2", STRING => "bootfile.bin"}
    ]
  })

Possible C<%args>:

=over 4

=item * mta_algorithm

This argument is required when encoding MTA config files. Can be set to
either empty string, "sha1" or "md5".

=item * shared_secret

This argument is optional, but will be used as the shared secret used to
increase security between the cable modem and CMTS.

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014-2018, Jan Henning Thorsen

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 CREDITS

=head2 Font Awesome

C<docsisious> bundles L<Font Awesome|https://fontawesome.com/>.

=head1 AUTHOR

Jan Henning Thorsen - C<jhthorsen@cpan.org>

=cut
