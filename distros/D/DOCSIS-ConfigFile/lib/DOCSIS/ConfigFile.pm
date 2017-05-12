package DOCSIS::ConfigFile;

=head1 NAME

DOCSIS::ConfigFile - Decodes and encodes DOCSIS config files

=head1 VERSION

0.71

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

See L<DOCSIS::ConfigFile::Syminfo/CONFIGURATION TREE> for full
set of possible parameters. Create an
L<issue|https://github.com/jhthorsen/docsis-configfile/issues> if a parameter
is missing or invalid.

=head1 SYNOPSIS

  use DOCSIS::ConfigFile qw( encode_docsis decode_docsis );

  $data = decode_docsis $bytes;

  $bytes = encode_docsis(
             {
               GlobalPrivacyEnable => 1,
               MaxCPE              => 2,
               NetworkAccess       => 1,
               BaselinePrivacy => {
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
               VendorSpecific => {
                 id => "0x0011ee",
                 options => [30 => "0xff", 31 => "0x00", 32 => "0x28"]
               }
             }
           );

See also L<DOCSIS::ConfigFile::Syminfo/CONFIGURATION TREE>.

=head1 OPTIONAL MODULE

You can install the L<SNMP.pm|SNMP> module to translate between SNMP
OID formats. With the module installed, you can define the C<SnmpMibObject>
like the example below, instead of using numeric OIDs:

  encode_docsis(
    {
      SnmpMibObject => [
        {oid => "docsDevNmAccessIp.1",     IPADDRESS => "10.0.0.1"},
        {oid => "docsDevNmAccessIpMask.1", IPADDRESS => "255.255.255.255"},
      ]
    },
  );

=cut

use strict;
use warnings;
use Digest::MD5 ();
use Digest::HMAC_MD5;
use Digest::SHA;
use DOCSIS::ConfigFile::Syminfo;
use DOCSIS::ConfigFile::Decode;
use DOCSIS::ConfigFile::Encode;
use constant DEBUG => $ENV{DOCSIS_CONFIGFILE_DEBUG} || 0;

use base 'Exporter';

our $VERSION = '0.71';
our @EXPORT_OK = qw( decode_docsis encode_docsis );
our $DEPTH     = 0;

=head1 FUNCTIONS

=head2 decode_docsis

  $data = decode_docsis($byte_string);
  $data = decode_docsis(\$path_to_file);

Used to decode a DOCSIS config file into a data structure. The output
C<$data> can be used as input to L</encode_docsis>. Note: C<$data>
will only contain array-refs if the DOCSIS parameter occur more than
once.

=cut

sub decode_docsis {
  my $args    = ref $_[-1] eq 'HASH' ? $_[-1] : {};
  my $bytes   = shift;
  my $current = $args->{blueprint} || $DOCSIS::ConfigFile::Syminfo::TREE;
  my $pos     = $args->{pos} || 0;
  my $data    = {};
  my $end;

  if (ref $bytes eq 'SCALAR') {
    my ($file, $r) = ($$bytes, 0);
    $bytes = '';
    open my $BYTES, '<', $file or die "decode_docsis $file: $!";
    while ($r = sysread $BYTES, my $buf, 131072, 0) { $bytes .= $buf }
    die "decode_docsis $file: $!" unless defined $r;
  }

  local $DEPTH = $DEPTH + 1 if DEBUG;
  $end = $args->{end} || length $bytes;

  while ($pos < $end) {
    my $code = unpack 'C', substr $bytes, $pos++, 1 or next;    # next on $code=0
    my ($length, $t, $name, $syminfo, $value);

    for (keys %$current) {
      next unless $code == $current->{$_}{code};
      $name    = $_;
      $syminfo = $current->{$_};
      last;
    }

    if (!$name) {
      warn "[DOCSIS] Internal error: No syminfo defined for code=$code.";
      next;
    }

    # Document: PKT-SP-PROV1.5-I03-070412
    # Chapter:  9.1 MTA Configuration File
    $t = $syminfo->{lsize} == 1 ? 'C' : 'n';    # 1=C, 2=n
    $length = unpack $t, substr $bytes, $pos, $syminfo->{lsize};
    $pos += $syminfo->{lsize};

    if ($syminfo->{nested}) {
      warn "[DOCSIS]@{[' 'x$DEPTH]}Decode $name [$pos, $length] with decode_docsis\n" if DEBUG;
      local @$args{qw( blueprint end pos)} = ($syminfo->{nested}, $length + $pos, $pos);
      $value = decode_docsis($bytes, $args);
    }
    elsif (my $f = DOCSIS::ConfigFile::Decode->can($syminfo->{func})) {
      warn "[DOCSIS]@{[' 'x$DEPTH]}Decode $name [$pos, $length] with $syminfo->{func}\n" if DEBUG;
      $value = $f->(substr $bytes, $pos, $length);
      $value = {oid => @$value{qw( oid type value )}} if $name eq 'SnmpMibObject';
    }
    else {
      die qq(Can't locate object method "$syminfo->{func}" via package "DOCSIS::ConfigFile::Decode");
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

=head2 encode_docsis

  $byte_string = encode_docsis(\%data, \%args);

Used to encode a data structure into a DOCSIS config file. Each of the keys
in C<$data> can either hold a hash- or array-ref. An array-ref is used if
the same DOCSIS parameter occur multiple times. These two formats will result
in the same C<$byte_string>:

  # Only one SnmpMibObject
  encode_docsis({
    SnmpMibObject => { # hash-ref
      oid => "1.3.6.1.4.1.1429.77.1.6.1.1.6.2", STRING => "bootfile.bin"
    }
  })

  # Allow one or more SnmpMibObjects
  encode_docsis({
    SnmpMibObject => [ # array-ref of hashes
      { oid => "1.3.6.1.4.1.1429.77.1.6.1.1.6.2", STRING => "bootfile.bin" }
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

=cut

sub encode_docsis {
  my ($data, $args) = @_;
  my $current = $args->{blueprint} || $DOCSIS::ConfigFile::Syminfo::TREE;
  my $mic     = {};
  my $bytes   = '';

  local $args->{depth} = ($args->{depth} || 0) + 1;
  local $DEPTH = $args->{depth} if DEBUG;

  if ($args->{depth} == 1 and defined $args->{mta_algorithm}) {
    delete $data->{MtaConfigDelimiter};
    $bytes .= encode_docsis({MtaConfigDelimiter => 1}, {depth => 1});
  }

  for my $name (sort { $current->{$a}{code} <=> $current->{$b}{code} } keys %$current) {
    next unless defined $data->{$name};
    my $syminfo = $current->{$name};
    my ($type, $length, $value);

    for my $item (ref $data->{$name} eq 'ARRAY' ? @{$data->{$name}} : $data->{$name}) {
      if ($syminfo->{nested}) {
        warn "[DOCSIS]@{[' 'x$DEPTH]}Encode $name with encode_docsis\n" if DEBUG;
        local @$args{qw( blueprint )} = ($current->{$name}{nested});
        $value = encode_docsis($item, $args);
      }
      elsif (my $f = DOCSIS::ConfigFile::Encode->can($syminfo->{func})) {
        warn "[DOCSIS]@{[' 'x$DEPTH]}Encode $name with $syminfo->{func}\n" if DEBUG;
        if ($name eq 'SnmpMibObject') {
          my @k = qw( type value );
          local $item->{oid} = $item->{oid};
          $value = pack 'C*', $f->({value => {oid => delete $item->{oid}, map { shift(@k), $_ } %$item}});
        }
        else {
          local $syminfo->{name} = $name;
          $value = pack 'C*', $f->({value => _validate($item, $syminfo)});
        }
      }
      else {
        die qq(Can't locate object method "$syminfo->{func}" via package "DOCSIS::ConfigFile::Encode");
      }

      $type = pack 'C', $syminfo->{code};
      $length = $syminfo->{lsize} == 2 ? pack('n', length $value) : pack('C', length $value);
      $mic->{$name} = "$type$length$value";
      $bytes .= $mic->{$name};
    }
  }

  return $bytes if $args->{depth} != 1;
  return _mta_eof($bytes, $args) if defined $args->{mta_algorithm};
  return _cm_eof($bytes, $mic, $args);
}

sub _cm_eof {
  my $mic      = $_[1];
  my $args     = $_[2];
  my $cmts_mic = '';
  my $pads     = 4 - (1 + length $_[0]) % 4;
  my $eod_pad;

  $mic->{CmMic} = pack('C*', 6, 16) . Digest::MD5::md5($_[0]);

  $cmts_mic .= $mic->{$_} || '' for @DOCSIS::ConfigFile::Syminfo::CMTS_MIC;
  $cmts_mic = pack('C*', 7, 16) . Digest::HMAC_MD5::hmac_md5($cmts_mic, $args->{shared_secret} || '');
  $eod_pad = pack('C', 255) . ("\0" x $pads);

  return $_[0] . $mic->{CmMic} . $cmts_mic . $eod_pad;
}

sub _mta_eof {
  my $mta_algorithm = $_[1]->{mta_algorithm} || '';
  my $hash = '';

  if ($mta_algorithm) {
    $hash = $mta_algorithm eq 'md5' ? Digest::MD5::md5_hex($_[0]) : Digest::SHA::sha1_hex($_[0]);
    $hash
      = encode_docsis({SnmpMibObject => {oid => '1.3.6.1.4.1.4491.2.2.1.1.2.7.0', STRING => "0x$hash"}}, {depth => 1});
  }

  return $hash . $_[0] . encode_docsis({MtaConfigDelimiter => 255}, {depth => 1});
}

# _validate($value, $syminfo);
sub _validate {
  if ($_[1]->{limit}[1]) {
    if ($_[0] =~ /^-?\d+$/) {
      die "[DOCSIS] $_[1]->{name} holds a too high value. ($_[0])" if $_[1]->{limit}[1] < $_[0];
      die "[DOCSIS] $_[1]->{name} holds a too low value. ($_[0])"  if $_[0] < $_[1]->{limit}[0];
    }
    else {
      my $length = length $_[0];
      die "[DOCSIS] $_[1]->{name} is too long. ($_[0])"  if $_[1]->{limit}[1] < $length;
      die "[DOCSIS] $_[1]->{name} is too short. ($_[0])" if $length < $_[1]->{limit}[0];
    }
  }
  return $_[0];
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014, Jan Henning Thorsen

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

Jan Henning Thorsen - C<jhthorsen@cpan.org>

=cut

1;
