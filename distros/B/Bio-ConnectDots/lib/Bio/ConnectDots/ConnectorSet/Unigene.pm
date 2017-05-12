package Bio::ConnectDots::ConnectorSet::Unigene;
use strict;
use vars qw(@ISA);
use Bio::ConnectDots::ConnectorSet;
@ISA = qw(Bio::ConnectDots::ConnectorSet);

sub parse_entry {
  my ($self) = @_;
  my $input_fh=$self->input_fh;
  
  while (<$input_fh>) {
    chomp;
    if (/^\/\//) {
      next unless $self->have_dots;
      return 1;
    }				
    if (/^ID/) {
      my ($field, $id) = split /\s+/;
      $self->put_dot('UniGene',$id);

    if ($id =~ /^Hs/) {
	$self->put_dot('Organism', 'Homo sapiens');
	}
                                                                                         
    if ($id =~ /^Mm/) {
        $self->put_dot('Organism', 'Mus musculus');
        }
    if ($id =~ /^Rn/) {
        $self->put_dot('Organism', 'Rattus norvegicus');
        }	
    }

    if (/^TITLE/) {
      my ($field, @title) = split /\s+/;
      $self->put_dot('Gene_Name',join(' ',@title));
    }
    if (/^GENE/) {
      my  ($field, $gene) = split /\s+/;
      $self->put_dot('Gene_Symbol', $gene);
    }
    if (/^LOCUSLINK/) {
      my ($field, @locuslink) = split /\s+/;
	foreach my $tmp (@locuslink) {
        $tmp =~ s/;//g;
	 $self->put_dot('LocusLink',$tmp);
      }
    }
    if (/^CHROMOSOME/) {
      my ($field, $chromosome) = split /\s+/;
      $self->put_dot('Chromosome',$chromosome);
    }
    if (/^STS/) {
      my ($field, $Acc, $sts) = split /=/;
      $sts =~ s/\s+//;
      if ($sts ne '-') {
      $self->put_dot( 'STS', $sts);
      }	
    }
    if (/^SEQUENCE/) {
     my @field = split /\s+/;   
	foreach my $tmp (@field) {
   
	if ($tmp =~ /ACC=/) {
	$tmp =~ s/ACC=//;
        $tmp =~ s/\.\d+;//;
      	$self->put_dot( 'Sequence_Accession', $tmp);
      }
      if ($tmp =~ /CLONE=/) {
      	$tmp =~ s/CLONE=//;
      	$tmp =~ s/;//;
      	$self->put_dot('Clone', $tmp);
      }
      if ($tmp =~ /LID=/) {	
      	$tmp =~ s/LID=//;
      	$tmp =~ s/;//;
      	$self->put_dot('LID', $tmp);
      }
      if ($tmp =~ /MGC=/){
	$tmp =~ s/MGC=//;
        $tmp =~ s/;//;
	$self->put_dot('MGC', $tmp);
      }	
} #foreach
      
    } #if /^SEQUENCE/
	
  }				#end of while
  return undef;
}				#end of sub

1;
