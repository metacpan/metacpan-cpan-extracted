package Bio::ConnectDots::ConnectorSet::EPconDBmousechip5;
use strict;
use vars qw(@ISA);
use Bio::ConnectDots::ConnectorSet;
@ISA = qw(Bio::ConnectDots::ConnectorSet);

sub parse_entry {
  my ($self) = @_;
  my $input_fh=$self->input_fh;
  
  while (<$input_fh>) {
    chomp;
    $_ =~ s/[\r\n]//;
    if (/^DoTS mouse build/) {next;}
    if (/^feature_location/i) {next;}
    #this is a tab delimited file
    my @field_array = split /\t/;
 
    my $Feature_Location = $field_array[0];
    $self->put_dot('Feature_Location', $Feature_Location);
   
    my $Kaestner_id = $field_array[1];
    $self->put_dot('Kaestner_ID', $Kaestner_id);
    
    my $Source = $field_array[2];
    my $Source_id = $field_array[3];
    my $datasource_and_id = $Source.':'.$Source_id;
    $self->put_dot('Source_and_ID',$datasource_and_id);

    my $locuslink = $field_array[5];
	if ($locuslink) {
        	if ($locuslink =~ /"/) {
        	my @ll = split (/,/, $locuslink);
        		foreach my $tmp (@ll) {
                		$tmp =~ s/"//;
          			$self->put_dot('LocusLink',$tmp);
        		}
                }
        	else{
         	$self->put_dot('LocusLink',$locuslink);
		}
	}

      my $locuslinksymbol = $field_array[6];
        if ($locuslinksymbol) {
                if ($locuslinksymbol =~ /"/) {
                my @lls = split (/,/, $locuslinksymbol);
                        foreach my $tmp (@lls) {
                                $tmp =~ s/"//;
                                $self->put_dot('LocuslinkSymbol',$tmp);
                        }
                }
                else{
                $self->put_dot('LocuslinkSymbol',$locuslinksymbol);
                }
        }

      my $locusgenename = $field_array[6];
        if ($locusgenename) {
                if ($locusgenename =~ /"/) {
                my @lgn = split (/,/, $locusgenename);
                        foreach my $tmp (@lgn) {
                                $tmp =~ s/"//;
                                $self->put_dot('LocusGeneName',$tmp);
                        }
                }
                else{
                $self->put_dot('LocusGeneName',$locusgenename);
                }
        }

     my $MGI_id = $field_array[9];
	if ($MGI_id) {
        	if ($MGI_id =~ /"/) {
        		my @mgi_id = split(/,/, $MGI_id);
        			foreach my $tmp (@mgi_id) {
                			$tmp =~ s/"//;
        				$self->put_dot('MGI_ID', $tmp);
                	}
		}
        	else {
		$self->put_dot('MGI_ID', $MGI_id); 
                }
    	}
    
#    my $MGI_symbol=$field_array[8];
#   	 if ($MGI_symbol) {
#        	if ($MGI_symbol =~ /"/) {
#        		my @mgi_sym = split(/,/, $MGI_symbol);
#        			foreach my $tmp (@mgi_sym) {
#                		$tmp =~ s/"//;
#        			$self->put_dot('MGI_Symbol', $tmp);
#			}
#                }
#        	else {
#    $self->put_dot('MGI_Symbol', $MGI_symbol);
#		}
#    	}
    
	
#    my $MGI_Synonyms_string = $field_array[9];
#    if ($MGI_Synonyms_string) {
#    $MGI_Synonyms_string =~ s/"//;
#    $MGI_Synonyms_string =~ s/"//;
#    my @temparray = split (/,/, $MGI_Synonyms_string);
#    foreach my $temp (@temparray) {
#    	$self->put_dot('MGI_SYNONYM', $temp);
#    	}
#    }

#    my $DoTS_Genesymbol_Desc = $field_array[10];
#        if ($DoTS_Genesymbol_Desc) {
#                $self->put_dot('DoTS_GeneSymbol_and_Desc',$DoTS_Genesymbol_Desc);
#                }
                                                                                                               
#    my $DoTS_Gene_Synonyms = $field_array[11];
#        if ($DoTS_Gene_Synonyms) {
#                if ($DoTS_Gene_Synonyms =~ /"/) {
#                my @dgs = split (/,/, $DoTS_Gene_Synonyms);
#                        foreach my $tmp (@dgs) {
#                                $tmp =~ s/"//;
#                                $self->put_dot('DoTS_Gene_Synonyms',$tmp);
#                        }
#                }
#                else{
#                $self->put_dot('DoTS_Gene_Synonyms',$DoTS_Gene_Synonyms);
#                }
#        }

      my $PCR_Failure_Flag = $field_array[15];
        if ($PCR_Failure_Flag) {
                $self->put_dot('PCR_Failure_Flag',$PCR_Failure_Flag);
                }
                                                                                                               
    my $Name = $field_array[4];
    if ($Name) {
    $self->put_dot('Name', $Name);
    }


   my $DoTS_id = $field_array[19];
        if ($DoTS_id) {
                 my @did = split (';', $DoTS_id);
                 foreach my $tmp (@did) {
                 	$tmp =~ s/"//;
                    $self->put_dot('DoTS_ID',$tmp);
                 }
        }
                                                                                                               
                                                                                                               
#    my $RNA_DESC = $field_array[15];
#        if ($RNA_DESC) {
#                $self->put_dot('RNA_DESC',$RNA_DESC);
#                }
                                                                                                               
#   my $Pred_GO_func = $field_array[16];
#        if ($Pred_GO_func) {
#                $self->put_dot('Predicted_GO_func',$Pred_GO_func);
#                }
   
#   my $Agencourt_seq_avail = $field_array[17];
#        if ($Agencourt_seq_avail) {
#                $self->put_dot('Agencourt_seq_avail',$Agencourt_seq_avail);
#                }

    my $seq_verified = $field_array[16];
        if ($seq_verified) {
                $self->put_dot('Seq_verified',$seq_verified);
                }
###17, 18, 11
   my $genbank = $field_array[11];
    if ($genbank) {
        my @genbankarray = split ('\s+', $genbank);
        push @genbankarray, $field_array[17];
        push @genbankarray, $field_array[18];
        foreach my $tmp (@genbankarray) {
                $tmp =~ s/"//;
      $self->put_dot('GenBank_Acc', $tmp);}
    }

#    my $WashU_name = $field_array[20];
#    if ($WashU_name) {
#      $self->put_dot('WashU_Name', $WashU_name);
#    }

#    my $Agencourt_IMAGE_ID = $field_array[21];
#    if ($Agencourt_IMAGE_ID) {
#      $self->put_dot('Agencourt_IMAGE_ID', $Agencourt_IMAGE_ID);
#    }
 
#    my $old_IMAGE_ID = $field_array[22];
#    if ($old_IMAGE_ID) {
#      $self->put_dot('old_IMAGE_ID', $old_IMAGE_ID);
#    }
                                                                                                
     my $RefSeq = $field_array[10];
    if ($RefSeq) {
	 if ($RefSeq =~ /"/) {
        	my @refseq = split(/,/, $RefSeq);
        	foreach my $tmp (@refseq) {
                	$tmp =~ s/"//;
        		$self->put_dot('RefSeq', $tmp);
                }
	}
        else {
        $self->put_dot('RefSeq', $RefSeq);
            }
     }


#    my $Plate_Name = $field_array[30];
#    if ($Plate_Name) {
#      $self->put_dot('Plate_Name', $Plate_Name);
#    }
                                                                                                               
#  my $well_location = $field_array[31];
#    if ($well_location) {
#      $self->put_dot('Well_Location', $well_location);
#    }


     return 1;
  }				#end of while
  return undef;
}				#end of sub

1;
