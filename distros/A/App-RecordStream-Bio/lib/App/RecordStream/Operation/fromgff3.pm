use strict;
use warnings;

package App::RecordStream::Operation::fromgff3;
use base qw(App::RecordStream::Operation);

use Bio::GFF3::LowLevel qw< gff3_parse_feature >;

sub init {
    my $this = shift;
    my $args = shift;
    my $options = {};
    $this->parse_options($args, $options);  # Ensures we pick up the automatic options
}

sub accept_line {
  my $this = shift;
  my $line = shift;

  # Skip headers, comments, and empty lines
  return 1 if $line =~ /^#|^$/;

  my $feature = gff3_parse_feature($line);

  $this->push_record( App::RecordStream::Record->new($feature) );
  return 1;
}

sub usage {
  my $this = shift;
  my $options = [];
  my $args_string = $this->options_string($options);

  return <<USAGE;
Usage: recs fromgff3 <args> [<files>]
   __FORMAT_TEXT__
   Each line of input (or lines of <files>) is parsed as a GFF3 (General
   Feature Format version 3) formatted record to produce a recs output record.

   The output records will contain the following fields:
   __FORMAT_TEXT__

      seq_id source type start end score strand phase attributes

   __FORMAT_TEXT__
   Additional feature attributes are parsed into the "attributes" key, which is a
   hash keyed by the attribute name.  The values are arrays.
   __FORMAT_TEXT__

   Refer to the GFF3 spec for field details:
     https://github.com/The-Sequence-Ontology/Specifications/blob/master/gff3.md

Arguments:
$args_string

Examples:
   Parse GFF3 and filter to just mRNA features:
      recs fromgff3 hg38.gff | recs grep '{{type}} eq "mRNA"'

USAGE
}

1;
