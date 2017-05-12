package Bio::ConnectDots::ConnectorSet::RefGene;
use strict;
use vars qw(@ISA);
use Bio::ConnectDots::ConnectorSet;
@ISA = qw(Bio::ConnectDots::ConnectorSet);

sub parse_entry {
  my ($self) = @_;
  my $input_fh=$self->input_fh;
  while (<$input_fh>) {
	 chomp;
	 my @field_array = split /\t/;
	 
	 my $refseqID = $field_array[0];
	 $self->put_dot('Refseq_ID', $refseqID);

	 my $strand = $field_array[2];
	 if ($strand) {
		$self->put_dot('Strand', $strand);
	 }
	 
	 my $chr = $field_array[1];
	 if ($chr) {
		$chr =~ s/chr//;
		$chr =~ s/_random//;
		$self->put_dot('Chromosome', $chr);
	 }
	 
	 my $t_start = $field_array[3];
	 if ($t_start) {
		$self->put_dot('Transcription_start', $t_start);
	 }
	 
	 my $t_end = $field_array[4];
	 if ($t_end) {
		$self->put_dot('Transcription_end', $t_end);
	 }

	 my $c_start = $field_array[5];
	 if ($c_start) {
		$self->put_dot('Coding_start', $c_start);
	 }
	 
	 my $c_end = $field_array[6];
	 if ($c_end) {
		$self->put_dot('Coding_end', $c_end);
	 }
	 	 		
	 return $self->have_dots;
  } #end of while
  return undef;
}#end of sub

1;
