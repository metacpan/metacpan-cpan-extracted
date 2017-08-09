use strict;
use warnings;

package App::RecordStream::Operation::fromsam;
use base qw(App::RecordStream::Operation);

sub init {
    my $self = shift;
    my $args = shift;
    my $options = {
      'flags'   => \($self->{'DECODE_FLAGS'}),
      'quals|Q' => \($self->{'DECODE_QUALS'}),
    };
    $self->parse_options($args, $options);  # Ensures we pick up the automatic options
}

sub accept_line {
  my $self = shift;
  my $line = shift;
  return 1 if $line =~ /^@/;  # Skip any header

  # Parse the mandatory fields
  my @fields = qw[ qname flag rname pos mapq cigar rnext pnext tlen seq qual ];
  my @values = split /\t/, $line;
  my %record = map { $_ => shift @values } @fields;

  # The remaining values are optional fields, which are composed of three parts
  # separated by a colon: TAG:TYPE:VALUE
  for my $tag (map { [split /:/, $_, 3] } @values) {
    $record{tag}{ $tag->[0] } = {
      type  => $tag->[1],
      value => $tag->[2],
    };
  }

  $record{quals} = [ map { ord($_) - 33 } split '', $record{qual} eq '*' ? '' : $record{qual} ]
    if $self->{'DECODE_QUALS'};

  if ($self->{'DECODE_FLAGS'}) {
    # Technically the flags to do with pairing and r1/r2 really refer
    # generically to multiple segments and first/last segments, but in practice
    # so far every one talks about pairing and first/second reads.  The SAM
    # spec is good about being precise, but `samtools flags` uses the monikers
    # below.
    #
    # 0x1   PAIRED        .. paired-end (or multiple-segment) sequencing technology
    # 0x2   PROPER_PAIR   .. each segment properly aligned according to the aligner
    # 0x4   UNMAP         .. segment unmapped
    # 0x8   MUNMAP        .. next segment in the template unmapped
    # 0x10  REVERSE       .. SEQ is reverse complemented
    # 0x20  MREVERSE      .. SEQ of the next segment in the template is reversed
    # 0x40  READ1         .. the first segment in the template
    # 0x80  READ2         .. the last segment in the template
    # 0x100 SECONDARY     .. secondary alignment
    # 0x200 QCFAIL        .. not passing quality controls
    # 0x400 DUP           .. PCR or optical duplicate
    # 0x800 SUPPLEMENTARY .. supplementary alignment
    $record{flag} ||= 0;
    $record{flags} = {
      paired        => !!($record{flag} & 0x1),
      proper_pair   => !!($record{flag} & 0x2),
      unmapped      => !!($record{flag} & 0x4),
      mate_unmapped => !!($record{flag} & 0x8),
      rc            => !!($record{flag} & 0x10),
      mate_rc       => !!($record{flag} & 0x20),
      r1            => !!($record{flag} & 0x40),
      r2            => !!($record{flag} & 0x80),
      secondary     => !!($record{flag} & 0x100),
      qc_failed     => !!($record{flag} & 0x200),
      duplicate     => !!($record{flag} & 0x400),
      supplementary => !!($record{flag} & 0x800),
    };
  }

  $self->push_record( App::RecordStream::Record->new(\%record) );
  return 1;
}

sub usage {
  my $self = shift;
  my $options = [
    ['flags', 'Decode flag bitstring into a "flags" hashref'],
    ['quals', 'Decode qual string into a "quals" array of numeric values'],
  ];
  my $args_string = $self->options_string($options);

  return <<USAGE;
Usage: recs fromsam <args> [<files>]
   __FORMAT_TEXT__
   Each line of input (or lines of <files>) is parsed as a SAM (Sequence
   Alignment/Map) formatted record to produce a recs output record.  To parse a
   BAM file, please pipe it from \`samtools view file.bam\` into this command.

   The output records will contain the following fields:
   __FORMAT_TEXT__

      qname flag rname pos mapq cigar rnext pnext tlen seq qual

   __FORMAT_TEXT__
   Additional optional SAM fields are parsed into the "tag" key, which is a
   hash keyed by the SAM field tag name.  The values are also hashes containing
   a "type" and "value" field.  For example, a read group tag will end up in your
   record like this:
   __FORMAT_TEXT__

      tags => {
        RG => {
          type  => "Z",
          value => "...",
        }
      }

   __FORMAT_TEXT__
   Refer to the SAM spec for field details: http://samtools.github.io/hts-specs/SAMv1.pdf
   __FORMAT_TEXT__

Arguments:
$args_string

Examples:
   Parse SAM and calculate average mapping quality:
      recs fromsam input.sam | recs collate -a avg,mapq
   Parse BAM:
      samtools view input.bam | recs fromsam
   Parse SAM pre-filtered by read group:
      samtools view -r SAMPLE-1234 input.sam | recs fromsam
   The same, but probably slower:
      recs fromsam input.sam | recs grep '{{tag/RG/value}} eq "SAMPLE-1234"'
USAGE
}

1;
