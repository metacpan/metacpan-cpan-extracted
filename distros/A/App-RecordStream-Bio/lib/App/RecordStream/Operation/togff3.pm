use strict;
use warnings;

package App::RecordStream::Operation::togff3;
use base qw(App::RecordStream::Operation);

use Bio::GFF3::LowLevel qw< gff3_format_feature >;

sub init {
    my $self = shift;
    my $args = shift;
    my $options = {};
    $self->parse_options($args, $options);  # Ensures we pick up the automatic options
}

sub accept_record {
    my $self   = shift;
    my $record = shift;

    my $feature = gff3_format_feature($record);

    $self->push_line("##gff-version 3")
        unless $self->{HEADER_EMITTED}++;

    chomp $feature;
    $self->push_line($feature);

    return 1;
}

sub usage {
    my $self = shift;
    my $options = [];
    my $args_string = $self->options_string($options);

    return <<USAGE;
Usage: recs togff3 <args> [<files>]
   __FORMAT_TEXT__
   Each input record is formatted as a GFF3 (General Feature Format version 3)
   line and output to stdout.

   The input records should contain the following fields:
   __FORMAT_TEXT__

      seq_id source type start end score strand phase attributes

   __FORMAT_TEXT__
   These are the same fields obtained when using the corresponding "fromgff3"
   command.
   __FORMAT_TEXT__

   Refer to the GFF3 spec for field details:
     https://github.com/The-Sequence-Ontology/Specifications/blob/master/gff3.md

Arguments:
$args_string

Examples:
   Parse GFF3 and filter to just mRNA features, writing back out GFF3:
      recs fromgff3 hg38.gff | recs grep '{{type}} eq "mRNA"' | recs togff3

USAGE
}

1;
