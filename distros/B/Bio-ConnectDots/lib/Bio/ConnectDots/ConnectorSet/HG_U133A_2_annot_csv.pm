package Bio::ConnectDots::ConnectorSet::HG_U133A_2_annot_csv;
use strict;
use vars qw(@ISA);
use Bio::ConnectDots::ConnectorSet;
@ISA = qw(Bio::ConnectDots::ConnectorSet);

sub parse_entry {
  my ($self) = @_;
  my $input_fh=$self->input_fh;
  	while (<$input_fh>) {
    		chomp;
    		if (/^"Probe Set ID"/) {
      			next;
    		}
    	
	my @field_array = split /","/;
    
    		my $probeSetID = $field_array[0];
    		$probeSetID =~ s/\"//;
		if ($probeSetID ne '---') {
		$self->put_dot('ProbeSet_ID', $probeSetID);
                }
                              
    		my $chip = $field_array[1];
		if ($chip ne '---') {
		$self->put_dot('Chip', $chip);
   		}

		my $organism = $field_array[2];
		if ($organism ne '---') {
		$self->put_dot('Organism', $organism);
		}

		my $sequenceType = $field_array[4];
		if ($sequenceType ne '---') {
                $self->put_dot('Sequence_Type', $sequenceType);
		}

		my $sequenceSource = $field_array[5];
		if ($sequenceSource ne '---') {
		$self->put_dot('Sequence_Source', $sequenceSource);
		}

		my $SDF = $field_array[6];
		if ($SDF ne '---') {
        	$SDF =~ s/\.\d+//;
		$self->put_dot('SequenceDerivedFrom', $SDF);
       		}
 
		my $geneSymbol=$field_array[12];
		if ($geneSymbol ne '---') {
		$self->put_dot('GeneSymbol', $geneSymbol);
		}	
		
		my $location=$field_array[13];
                if ($location ne '---') {
                $self->put_dot('Location', $location);
                }
	
		my $unigene = $field_array[14];
        	$unigene =~ s/\s*\/\/\s*\S*\s*\S*\s*\S*//;
                if ($unigene ne '---'){
		$self->put_dot('UniGene', $unigene);
		}

		my $locuslink = $field_array[15];
		if ($locuslink ne '---') {		
		$self->put_dot('LocusLink', $locuslink);}

		my $swissProt = $field_array[16];
		if ($swissProt ne '---') {
                        if ($swissProt =~ /\/\/\//) {
                                my @sp = split(/\/\/\//, $swissProt);
                                foreach my $tmp (@sp) {
                                        $tmp =~ s/\s*//;
                                        $self->put_dot('SwissProt', $tmp);
                                }
                        }
                        else {
                        $self->put_dot('SwissProt', $swissProt);
                        }
                }

		my $ECnumber = $field_array[17];
		if ($ECnumber ne '---') {
		$self->put_dot('ECnumber', $ECnumber);}
		
		my $omim = $field_array[18];
		if ($omim ne '---') {		
		$self->put_dot('OMIM', $omim);}
		
		my $ensemblID = $field_array[19];
		 if ($ensemblID ne '---'){
                        if ($ensemblID =~ /\/\/\//) {
                                my @ensemblid = split (/\/\/\//, $ensemblID);
                                foreach my $tmp (@ensemblid) {
                                        $tmp =~ s/\s*//;
                                        $self->put_dot('Ensembl', $tmp);
                                }
                 	}
                 	else {
                 	$self->put_dot('Ensembl', $ensemblID);
                 	}
		}

		
	 	return $self->have_dots;
	} #end of while
	return undef;
}#end of sub

1;
