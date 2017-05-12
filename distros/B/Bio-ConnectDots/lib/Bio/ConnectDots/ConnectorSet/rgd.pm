package Bio::ConnectDots::ConnectorSet::rgd;
use strict;
use vars qw(@ISA);
use Bio::ConnectDots::ConnectorSet;
@ISA = qw(Bio::ConnectDots::ConnectorSet);

sub parse_entry {
  my ($self) = @_;
  my $input_fh=$self->input_fh;
  while (<$input_fh>) {
	 chomp;
	 if (/^"GENE_RGD_ID"/) {
		next;
	 }
	 my @field_array = split /\t/;
	 my $rgdID = $field_array[0];
	 $rgdID =~ s/\s//;
	 $self->put_dot('RGD_ID', $rgdID);

	 my $symbol = $field_array[1];
	 if ($symbol) {
		$self->put_dot('Gene_Symbol', $symbol);
	 }
	 
	 my $chr = $field_array[4];
	 if ($chr) {
		$self->put_dot('Chromosome', $chr);
	 }
	 
	 my $ratmap_id = $field_array[9];
	 if ($ratmap_id) {
		$self->put_dot('Ratmap_ID', $ratmap_id);
	 }
	 
	 my $ll_id = $field_array[10];
	 if ($ll_id) {
		$self->put_dot('Gene_ID', $ll_id);
	 }
 
	 my $swp_id = $field_array[11];
	 if ($swp_id) {
		$self->put_dot('Swissprot_ID', $swp_id);
	 }

	 my $genbank_list = $field_array[14];
	 my @genbank = split(',', $genbank_list);
	 foreach my $gb (@genbank) {
	 	if ($gb) {
		$self->put_dot('Genbank_ID', $gb);
	 	}
	 }

	 my $tigr_list = $field_array[15];
	 my @tigr = split(',', $tigr_list);
	 foreach my $tigr (@tigr) {
	 	if ($tigr) {
		$self->put_dot('TIGR_ID', $tigr);
	 	}
	 }

	 my $unigene = $field_array[17];
	 if ($unigene) {
		$self->put_dot('Unigene_ID', $unigene);
	 }
	 
	 my $mouse_rgd = $field_array[18];
	 if ($mouse_rgd) {
		$self->put_dot('Mouse_homolog_RGD_ID', $mouse_rgd);
	 }
	 
	 my $mgd_id = $field_array[22];
	 if ($mgd_id) {
	 	$mgd_id =~ s/MGI\://;
		$self->put_dot('MGD_ID', $mgd_id);
	 }
	 
	 my $human_rgd = $field_array[23];
	 if ($human_rgd) {
		$self->put_dot('Human_homolog_RGD_ID', $human_rgd);
	 }
	 		
	 return $self->have_dots;
  } #end of while
  return undef;
}#end of sub

1;
