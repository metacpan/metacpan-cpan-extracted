package Bio::ConnectDots::ConnectorSet::EPconDBhumanchip1;
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
    if (/^DoTS human build/) {next;}
    if (/^Feature_Location/) {next;}
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

    my $Name = $field_array[6];
    $self->put_dot('Name', $Name) if $Name;

    my $locuslink = $field_array[4];
	if ($locuslink) {
       	my @ll = split (';\s*', $locuslink);
   		foreach my $tmp (@ll) {
       		$tmp =~ s/"//;
   			$self->put_dot('LocusLink',$tmp);
   		}
    }

      my $GeneCards = $field_array[7];
        if ($GeneCards) {
                if ($GeneCards =~ /"/) {
                my @gc = split (/,/, $GeneCards);
                        foreach my $tmp (@gc) {
                                $tmp =~ s/"//;
                                $self->put_dot('GeneCards',$tmp);
                        }
                }
                else{
                $self->put_dot('GeneCards',$GeneCards);
                }
        }

      my $HUGO_GENE_SYMBOL = $field_array[8];
        if ($HUGO_GENE_SYMBOL) {
                if ($HUGO_GENE_SYMBOL =~ /"/) {
                my @hgs = split (/,/, $HUGO_GENE_SYMBOL);
                        foreach my $tmp (@hgs) {
                                $tmp =~ s/"//;
                                $self->put_dot('HUGO_GENE_SYMBOL',$tmp);
                        }
                }
                else{
                $self->put_dot('HUGO_GENE_SYMBOL',$HUGO_GENE_SYMBOL);
                }
        }

       my $HUGO_GENE_DESC = $field_array[9];
        if ($HUGO_GENE_DESC) {
                $self->put_dot('HUGO_GENE_DESC',$HUGO_GENE_DESC);
                }
        
      my $HUGO_GENE_SYNONYM = $field_array[10];
        if ($HUGO_GENE_SYNONYM) {
                if ($HUGO_GENE_SYNONYM =~ /"/) {
                my @hgsm = split (/,/, $HUGO_GENE_SYNONYM);
                        foreach my $tmp (@hgsm) {
                                $tmp =~ s/"//;
                                $self->put_dot('HUGO_GENE_SYNONYM',$tmp);
                        }
                }
                else{
                $self->put_dot('HUGO_GENE_SYNONYM',$HUGO_GENE_SYNONYM);
                }
        }


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

   my $PCR_Failure_Flag = $field_array[11];
        if ($PCR_Failure_Flag) {
                $self->put_dot('PCR_Failure_Flag',$PCR_Failure_Flag);
                }

   

   my $DoTS_id = $field_array[13];
        if ($DoTS_id) {
                if ($DoTS_id =~ /"/) {
                my @did = split (/,/, $DoTS_id);
                        foreach my $tmp (@did) {
                                $tmp =~ s/"//;
                                $self->put_dot('DoTS_ID',$tmp);
                        }
                }
                else{
                $self->put_dot('DoTS_ID',$DoTS_id);
                }
        }


    my $RNA_DESC = $field_array[14];
        if ($RNA_DESC) {
                $self->put_dot('RNA_DESC',$RNA_DESC);
                }

   my $Pred_GO_func = $field_array[15];
        if ($Pred_GO_func) {
                $self->put_dot('Predicted_GO_func',$Pred_GO_func);
                }

    my $seq_verified = $field_array[16];
        if ($seq_verified) {
                $self->put_dot('Seq_verified',$seq_verified);
                }
  
   my $IMAGE_ID = $field_array[17];
        if ($IMAGE_ID) {
                if ($IMAGE_ID =~ /"/) {
                my @iid = split (/,/, $IMAGE_ID);
                        foreach my $tmp (@iid) {
                                $tmp =~ s/"//;
                                $self->put_dot('IMAGE_ID',$tmp);
                        }
                }
                else{
                $self->put_dot('IMAGE_ID',$IMAGE_ID);
                }
        }


    my $genbank = $field_array[18];
    if ($genbank) {
        my @genbankarray = split (/,/, $genbank);
        foreach my $tmp (@genbankarray) {
                $tmp =~ s/"//;
      $self->put_dot('GenBank_Acc', $tmp);}
    }

    my $WashU_name = $field_array[19];
    if ($WashU_name) {
      $self->put_dot('WashU_Name', $WashU_name);
    }

    my $RefSeq = $field_array[21];
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


  my $Plate_Name = $field_array[30];
    if ($Plate_Name) {
      $self->put_dot('Plate_Name', $Plate_Name);
    }

  my $well_location = $field_array[31];
    if ($well_location) {
      $self->put_dot('Well_Location', $well_location);
    }

  my $DNA_cons = $field_array[32];
    if ($DNA_cons) {
      $self->put_dot('DNA_Concentration', $DNA_cons);
    }

     return 1;
  }				#end of while
  return undef;
}				#end of sub

1;
