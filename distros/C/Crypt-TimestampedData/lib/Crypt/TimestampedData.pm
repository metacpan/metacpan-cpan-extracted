package Crypt::TimestampedData;
$Crypt::TimestampedData::VERSION = '0.01';
use strict;
use warnings;

use Convert::ASN1;

=pod

=head1 NAME

Crypt::TimestampedData - Read and write TimeStampedData files (.TSD, RFC 5544)

=head1 VERSION

version 0.01

=head1 SYNOPSIS

  use Crypt::TimestampedData;

  # Decode from .TSD file
  my $tsd = Crypt::TimestampedData->read_file('/path/file.tsd');
  my $version           = $tsd->{version};
  my $data_uri          = $tsd->{dataUri};        # optional
  my $meta              = $tsd->{metaData};       # optional
  my $content_der       = $tsd->{content};        # optional (CMS ContentInfo DER)
  my $evidence_content  = $tsd->{temporalEvidence};

  # Encode to .TSD file
  Crypt::TimestampedData->write_file('/path/out.tsd', $tsd);

=head1 DESCRIPTION

Minimal implementation of the TimeStampedData format (RFC 5544) using Convert::ASN1.
This version treats CMS constructs and TimeStampTokens as opaque DER blobs.
The goal is to enable reading/writing of .TSD files, delegating CMS/TS handling
to external libraries when available.

=head1 METHODS

=head2 new(%args)

Creates a new Crypt::TimestampedData object with the provided arguments.

=head2 read_file($filepath)

Reads and decodes a .TSD file from the specified path. Returns a hash reference
containing the decoded TimeStampedData structure.

=head2 write_file($filepath, $tsd_hashref)

Encodes and writes a TimeStampedData structure to the specified file path.

=head2 decode_der($der)

Decodes DER-encoded TimeStampedData. Handles both direct TSD format and
CMS ContentInfo wrappers (id-ct-TSTData and pkcs7-signedData).

=head2 encode_der($tsd_hashref)

Encodes a TimeStampedData hash reference to DER format.

=head2 extract_content_der($tsd_hashref)

Extracts the embedded original content from TimeStampedData.content.
Returns raw bytes of the original file if available, otherwise undef.

=head2 extract_tst_tokens_der($tsd_hashref)

Extracts RFC 3161 TimeStampToken(s) as DER ContentInfo blobs.
Returns array reference of DER-encoded ContentInfo tokens.

=head2 write_content_file($tsd_hashref, $filepath)

Convenience method to write extracted content to a file.

=head2 extract_signed_content_bytes($tsd_hashref)

Extracts encapsulated content from a SignedData (p7m) stored in TSD.content.
Returns raw bytes of the signed payload (eContent) when available.

=head2 write_signed_content_file($tsd_hashref, $filepath)

Convenience method to write extracted signed content to a file.

=head2 write_tst_files($tsd_hashref, $dirpath)

Writes extracted timestamp tokens to individual .tsr files in the specified directory.

=head2 write_tds($marked_filepath, $tsr_input, $out_filepath_opt)

Creates and writes a TSD file from a marked file and one or more RFC3161
TimeStampToken(s) provided as .TSR (DER CMS ContentInfo) blobs or paths.

=head1 EXAMPLES

  # Read a TSD file
  my $tsd = Crypt::TimestampedData->read_file('document.tsd');
  print "Version: $tsd->{version}\n";
  
  # Extract the original content
  Crypt::TimestampedData->write_content_file($tsd, 'original_document.pdf');
  
  # Extract timestamp tokens
  my $tokens = Crypt::TimestampedData->extract_tst_tokens_der($tsd);
  print "Found " . scalar(@$tokens) . " timestamp tokens\n";
  
  # Create a new TSD file
  my $output = Crypt::TimestampedData->write_tds(
    'document.pdf',           # original file
    'timestamp.tsr',          # timestamp token
    'document.tsd'           # output file
  );

=head1 COMMAND-LINE SCRIPTS

This distribution includes several command-line scripts for working with TimeStampedData files:

=over 4

=item * C<tsd-create> - Create a .tsd file from a file and timestamp

=item * C<tsd-extract> - Extract content and timestamps from a .tsd file

=item * C<tsd-info> - Display information about a .tsd file

=back

=head2 Windows Usage

On Windows systems, scripts must be executed with Perl explicitly:

  perl tsd-create --help
  perl tsd-extract document.tsd
  perl tsd-info document.tsd

=head2 Unix/Linux Usage

On Unix/Linux systems, scripts can be executed directly:

  tsd-create --help
  tsd-extract document.tsd
  tsd-info document.tsd

=head1 REQUIREMENTS

=over 4

=item * Convert::ASN1

=back

=head1 AUTHOR

Guido Brugnara <gdo@leader.it> - created with AI support.

=head1 LICENSE

This module is released under the same terms as Perl itself.

=head1 SEE ALSO

=over 4

=item * RFC 5544 - TimeStampedData Format

=item * RFC 3161 - Internet X.509 Public Key Infrastructure Time-Stamp Protocol

=item * RFC 5652 - Cryptographic Message Syntax (CMS)

=back

=cut

my $ASN1_SPEC = <<'__ASN1_RFC5544__';
  TimeStampedData ::= SEQUENCE {
    version            INTEGER,
    dataUri            IA5String OPTIONAL,
    metaData           MetaData OPTIONAL,
    content            OCTET STRING OPTIONAL,   -- ContentInfo DER (RFC 5652)
    temporalEvidence   Evidence
  }

  MetaData ::= SEQUENCE {
    hashProtected  BOOLEAN,
    fileName       UTF8String OPTIONAL,
    mediaType      IA5String OPTIONAL,
    otherMetaData  ANY OPTIONAL
  }

      Evidence ::= CHOICE {
         tstEvidence    [0] TimeStampTokenEvidence,   -- see RFC 3161
         ersEvidence    [1] EvidenceRecord,           -- see RFC 4998
         otherEvidence  [2] OtherEvidence
      }

      OtherEvidence ::= SEQUENCE {
         oeType            OBJECT IDENTIFIER,
         oeValue           ANY DEFINED BY oeType }

      TimeStampTokenEvidence ::=
         SEQUENCE OF TimeStampAndCRL

      TimeStampAndCRL ::= SEQUENCE {
         timeStamp   TimeStampToken,          -- according to RFC 3161
         crl         CertificateList OPTIONAL -- according to RFC 5280
      }

  TimeStampToken ::= ContentInfo

  CertificateList ::= ANY

  Attribute ::= ANY

  EvidenceRecord ::= ANY
  -- OtherEvidence payload defined above (oeType, oeValue)

  -- Minimal CMS ContentInfo wrapper (RFC 5652)
  ContentInfo ::= SEQUENCE {
    contentType   OBJECT IDENTIFIER,
    content       [0] EXPLICIT ANY OPTIONAL
  }


  -- Helper to unwrap OCTET STRING containers when needed
  OctetString ::= OCTET STRING

  -- Minimal CMS structures to navigate SignedData → EncapsulatedContentInfo
  SignedData ::= SEQUENCE {
    version                INTEGER,
    digestAlgorithms       SET OF AlgorithmIdentifier,
    encapContentInfo       EncapsulatedContentInfo,
    certificates           [0] IMPLICIT ANY OPTIONAL,
    crls                   [1] IMPLICIT ANY OPTIONAL,
    signerInfos            SET OF ANY
  }

  EncapsulatedContentInfo ::= SEQUENCE {
    eContentType           OBJECT IDENTIFIER,
    eContent               [0] EXPLICIT OCTET STRING OPTIONAL
  }

  AlgorithmIdentifier ::= SEQUENCE {
    algorithm              OBJECT IDENTIFIER,
    parameters             ANY OPTIONAL
  }

__ASN1_RFC5544__

my $ASN1 = Convert::ASN1->new;
$ASN1->prepare($ASN1_SPEC) or die "TSD ASN.1 prepare error: " . $ASN1->error;

my $TSD_CODEC = $ASN1->find('TimeStampedData')
  or die 'ASN.1 type TimeStampedData not found';

my $CONTENTINFO_CODEC = $ASN1->find('ContentInfo')
  or die 'ASN.1 type ContentInfo not found';

my $OCTETSTRING_CODEC = $ASN1->find('OctetString')
  or die 'ASN.1 type OctetString not found';

my $SIGNEDDATA_CODEC = $ASN1->find('SignedData')
  or die 'ASN.1 type SignedData not found';

my $CONTENTINFO_TSD_CODEC = $ASN1->find('ContentInfoTSD')
  or undef;

my $OID_CT_TSTDATA = '1.2.840.113549.1.9.16.1.31';
my $OID_CT_SIGNEDDATA = '1.2.840.113549.1.7.2';

sub new {
  my ($class, %args) = @_;
  my $self = {%args};
  return bless $self, $class;
}

sub decode_der {
  my ($class, $der) = @_;

  # Try direct TimeStampedData first
  my $decoded = $TSD_CODEC->decode($der);
  return $decoded if defined $decoded;

  # If that fails, try unwrapping CMS ContentInfo (common packaging for TSD)
  my $ci = $CONTENTINFO_CODEC->decode($der);
  die 'ASN.1 decode failed: ' . $TSD_CODEC->error unless defined $ci;

  # Two acceptable wrappings for RFC 5544:
  # 1) ContentInfo with contentType id-ct-TSTData and [0] content = TimeStampedData
  # 2) ContentInfo with contentType pkcs7-signedData, whose encapContentInfo.eContentType is id-ct-TSTData

  my $content_der = $ci->{content};
  die 'ASN.1 decode failed: ContentInfo without [0] content' unless defined $content_der;

  # Some encoders place TSD directly as [0] EXPLICIT SEQUENCE; others wrap as OCTET STRING
  my $first_tag = length($content_der) ? ord(substr($content_der, 0, 1)) : -1;
  if ($first_tag == 0x04) { # OCTET STRING
    my $octets = $OCTETSTRING_CODEC->decode($content_der);
    die 'ASN.1 decode failed: cannot unwrap OCTET STRING: ' . $OCTETSTRING_CODEC->error unless defined $octets;
    $content_der = $octets;
  }

  # Case 1: Direct id-ct-TSTData wrapper — decode TSD from [0] content (may be OCTET STRING)
  if (defined $ci->{contentType} && $ci->{contentType} eq $OID_CT_TSTDATA) {
    my $tsd = $TSD_CODEC->decode($content_der);
    die 'ASN.1 decode failed (inside ContentInfo/id-ct-TSTData): ' . $TSD_CODEC->error unless defined $tsd;
    return $tsd;
  }

  # Case 2: SignedData → EncapsulatedContentInfo with id-ct-TSTData
  if (defined $ci->{contentType} && $ci->{contentType} eq $OID_CT_SIGNEDDATA) {
    my $sd = $SIGNEDDATA_CODEC->decode($content_der);
    die 'ASN.1 decode failed: cannot decode SignedData: ' . $SIGNEDDATA_CODEC->error unless defined $sd;
    my $eci = $sd->{encapContentInfo} || {};
    my $econtent_type = $eci->{eContentType};
    my $econtent = $eci->{eContent};
    die 'ASN.1 decode failed: SignedData without encapContentInfo.eContent' unless defined $econtent;
    unless (defined $econtent_type && $econtent_type eq $OID_CT_TSTDATA) {
      die "Input is CMS SignedData with eContentType '$econtent_type', expected id-ct-TSTData ($OID_CT_TSTDATA).";
    }
    # eContent is an OCTET STRING wrapping the TSD DER
    my $tsd = $TSD_CODEC->decode($econtent);
    die 'ASN.1 decode failed (inside SignedData/id-ct-TSTData): ' . $TSD_CODEC->error unless defined $tsd;
    return $tsd;
  }

  die "Input ContentInfo has unsupported contentType '$ci->{contentType}', expected id-ct-TSTData ($OID_CT_TSTDATA) or pkcs7-signedData ($OID_CT_SIGNEDDATA).";
}

sub encode_der {
  my ($class, $tsd_hashref) = @_;
  my $der = $TSD_CODEC->encode($tsd_hashref);
  die 'ASN.1 encode failed: ' . $TSD_CODEC->error unless defined $der;
  return $der;
}

sub read_file {
  my ($class, $filepath) = @_;
  open my $fh, '<:raw', $filepath or die "Cannot open TSD file '$filepath' for reading: $!";
  local $/; my $der = <$fh>; close $fh;
  return $class->decode_der($der);
}

sub write_file {
  my ($class, $filepath, $tsd_hashref) = @_;
  my $der = $class->encode_der($tsd_hashref);
  open my $fh, '>:raw', $filepath or die "Cannot open TSD file '$filepath' for writing: $!";
  print {$fh} $der;
  close $fh;
  return 1;
}

# Extract embedded original content from TimeStampedData.content
# Returns raw bytes of the original file if available, otherwise undef
sub extract_content_der {
  my ($class, $tsd_hashref) = @_;
  my $content_der = $tsd_hashref->{content};
  return undef unless defined $content_der;

  # content is a CMS ContentInfo (DER). Try to unwrap eContent when present
  my $ci = $CONTENTINFO_CODEC->decode($content_der);
  return $content_der unless defined $ci; # if decoding fails, return raw blob (treat as opaque)

  my $content_type = $ci->{contentType};
  my $econtent = $ci->{content};
  return undef unless defined $econtent; # no encapsulated content

  # If the ContentInfo is id-data, unwrap to the raw bytes; otherwise
  # (e.g., SignedData/p7m), return the full ContentInfo DER as the original file
  if (defined $content_type && $content_type eq '1.2.840.113549.1.7.1') { # id-data
    my $first_tag = length($econtent) ? ord(substr($econtent, 0, 1)) : -1;
    if ($first_tag == 0x04) {
      my $octets = $OCTETSTRING_CODEC->decode($econtent);
      return $octets if defined $octets;
    }
    return $econtent; # fallback: return inner content as-is
  }

  # For SignedData and others: preserve outer ContentInfo (p7m)
  return $content_der;
}

# Extract RFC 3161 TimeStampToken(s) as DER ContentInfo blobs
# Returns arrayref of DER-encoded ContentInfo tokens
sub extract_tst_tokens_der {
  my ($class, $tsd_hashref) = @_;
  my @tokens_der;

  my $evidence = $tsd_hashref->{temporalEvidence};
  return \@tokens_der unless defined $evidence;

  if (exists $evidence->{tstEvidence}) {
    foreach my $ts_and_crl (@{ $evidence->{tstEvidence} || [] }) {
      my $ci_struct = $ts_and_crl->{timeStamp};
      next unless defined $ci_struct;
      my $der = $CONTENTINFO_CODEC->encode($ci_struct);
      push @tokens_der, $der if defined $der;
    }
  }
  return \@tokens_der;
}

# Convenience helpers to write extracted payloads
sub write_content_file {
  my ($class, $tsd_hashref, $filepath) = @_;
  my $bytes = $class->extract_content_der($tsd_hashref);
  die 'No embedded content found in TSD' unless defined $bytes;
  open my $fh, '>:raw', $filepath or die "Cannot open '$filepath' for writing: $!";
  print {$fh} $bytes;
  close $fh;
  return 1;
}

## Extract encapsulated content from a SignedData (p7m) stored in TSD.content.
## Returns raw bytes of the signed payload (eContent) when available.
sub extract_signed_content_bytes {
  my ($class, $tsd_hashref) = @_;
  my $content_der = $tsd_hashref->{content};
  return undef unless defined $content_der;

  my $ci = $CONTENTINFO_CODEC->decode($content_der) or return undef;
  return undef unless defined $ci->{contentType} && $ci->{contentType} eq $OID_CT_SIGNEDDATA;
  my $sd_der = $ci->{content};
  my $sd = $SIGNEDDATA_CODEC->decode($sd_der) or return undef;
  my $eci = $sd->{encapContentInfo} || {};
  my $econtent = $eci->{eContent};
  return undef unless defined $econtent;
  # eContent is EXPLICIT OCTET STRING; unwrap if needed
  my $first_tag = length($econtent) ? ord(substr($econtent, 0, 1)) : -1;
  if ($first_tag == 0x04) {
    my $octets = $OCTETSTRING_CODEC->decode($econtent);
    return $octets if defined $octets;
  }
  return $econtent;
}

sub write_signed_content_file {
  my ($class, $tsd_hashref, $filepath) = @_;
  my $bytes = $class->extract_signed_content_bytes($tsd_hashref);
  die 'No encapsulated signed content found in TSD.content' unless defined $bytes;
  open my $fh, '>:raw', $filepath or die "Cannot open '$filepath' for writing: $!";
  print {$fh} $bytes;
  close $fh;
  return 1;
}

sub write_tst_files {
  my ($class, $tsd_hashref, $dirpath) = @_;
  my $tokens = $class->extract_tst_tokens_der($tsd_hashref);
  my $index = 1;
  foreach my $der (@$tokens) {
    my $out = "$dirpath/timestamp_$index.tsr"; # DER CMS ContentInfo
    open my $fh, '>:raw', $out or die "Cannot open '$out' for writing: $!";
    print {$fh} $der;
    close $fh;
    $index++;
  }
  return scalar(@$tokens);
}

###
# Create and write a TSD file from a marked file and one or more RFC3161
# TimeStampToken(s) provided as .TSR (DER CMS ContentInfo) blobs or paths.
#
# Usage examples:
#   # single token, infer output path as <file>.tsd
#   my $out = Crypt::TimestampedData->write_tds('/path/file.bin', '/path/token.tsr');
#
#   # multiple tokens
#   my $out = Crypt::TimestampedData->write_tds('/path/file.bin', [ '/p/a.tsr', '/p/b.tsr' ], '/path/out.tsd');
#
# Args:
#   $marked_filepath  - path to the original file to embed
#   $tsr_input        - path to .tsr, raw DER bytes, or ARRAYREF of these
#   $out_filepath_opt - optional output .tsd path; defaults to "$marked_filepath" with .tsd extension
#
# Returns output filepath on success.
sub write_tds {
  my ($class, $marked_filepath, $tsr_input, $out_filepath_opt) = @_;

  die 'Marked file path is required' unless defined $marked_filepath;
  open my $in_fh, '<:raw', $marked_filepath or die "Cannot open marked file '$marked_filepath' for reading: $!";
  local $/; my $marked_bytes = <$in_fh>; close $in_fh;

  # If the marked bytes are already a CMS ContentInfo (e.g., .p7m), embed as-is.
  # Otherwise, build a ContentInfo (id-data) wrapping the raw bytes.
  my $contentinfo_der;
  my $ci_probe = $CONTENTINFO_CODEC->decode($marked_bytes);
  if (defined $ci_probe && ref $ci_probe eq 'HASH' && exists $ci_probe->{contentType}) {
    $contentinfo_der = $marked_bytes; # already a ContentInfo
  } else {
    my $DATA_OID = '1.2.840.113549.1.7.1'; # id-data
    my $octets_der = $OCTETSTRING_CODEC->encode($marked_bytes)
      or die 'ASN.1 encode failed for OctetString: ' . $OCTETSTRING_CODEC->error;
    $contentinfo_der = $CONTENTINFO_CODEC->encode({ contentType => $DATA_OID, content => $octets_der })
      or die 'ASN.1 encode failed for ContentInfo (data): ' . $CONTENTINFO_CODEC->error;
  }

  # Normalize $tsr_input to an array of DER-encoded TimeStampToken ContentInfo blobs
  my @tsr_items = ref($tsr_input) eq 'ARRAY' ? @$tsr_input : ($tsr_input);
  die 'At least one .TSR token must be provided' unless @tsr_items;

  my @tst_seq;
  for my $item (@tsr_items) {
    my $der;
    if (defined $item && !ref($item) && -e $item) {
      open my $fh, '<:raw', $item or die "Cannot open TSR file '$item' for reading: $!";
      local $/; $der = <$fh>; close $fh;
    } else {
      $der = $item;
    }
    die 'Undefined TSR DER provided' unless defined $der && length $der;
    my $ci_struct = $CONTENTINFO_CODEC->decode($der)
      or die 'ASN.1 decode failed for TSR (expecting ContentInfo/TimeStampToken): ' . $CONTENTINFO_CODEC->error;
    push @tst_seq, { timeStamp => $ci_struct };
  }

  my ($fname) = $marked_filepath =~ m{([^/]+)$};
  my $tsd_hashref = {
    version => 1,
    metaData => {
      hashProtected => 0,
      (defined $fname ? (fileName => $fname) : ()),
    },
    content => $contentinfo_der,
    temporalEvidence => {
      tstEvidence => \@tst_seq,
    },
  };

  # Determine output path
  my $out = $out_filepath_opt;
  unless (defined $out && length $out) {
    $out = $marked_filepath;
    $out =~ s{(\.[^/\.]+)?$}{.tsd};
  }

  # For better interoperability, wrap TSD as CMS ContentInfo with id-ct-TSTData
  my $tsd_der = $TSD_CODEC->encode($tsd_hashref)
    or die 'ASN.1 encode failed for TimeStampedData: ' . $TSD_CODEC->error;
  my $ci_tsd_der = $CONTENTINFO_CODEC->encode({ contentType => $OID_CT_TSTDATA, content => $tsd_der })
    or die 'ASN.1 encode failed for ContentInfo(id-ct-TSTData): ' . $CONTENTINFO_CODEC->error;
  open my $out_fh, '>:raw', $out or die "Cannot open TSD file '$out' for writing: $!";
  print {$out_fh} $ci_tsd_der;
  close $out_fh;
  return $out;
}

1;
