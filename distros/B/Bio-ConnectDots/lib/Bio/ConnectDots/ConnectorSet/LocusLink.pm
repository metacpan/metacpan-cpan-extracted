package Bio::ConnectDots::ConnectorSet::LocusLink;
use strict;
use vars qw(@ISA);
use Bio::ConnectDots::ConnectorSet;
@ISA = qw(Bio::ConnectDots::ConnectorSet);

sub parse_entry {
  my ($self) = @_;
  my $input_fh=$self->input_fh;
  
  while (<$input_fh>) {
    chomp;
    if (/^>>/) {
      next unless $self->have_dots;
      return 1;
    }				#end of if
    if (/^LOCUSID:/) {
      my($field, $llid) = split /:\s*/;
      $self->put_dot('LocusLink',$llid);
    }
    if (/^UNIGENE:/) {
      my($field, $unigene) = split /:\s*/;
      $self->put_dot('UniGene',$unigene);
    }
    if (/^ORGANISM:/) {
      my ($field, $organism) = split /:\s*/;
      $self->put_dot('Organism',$organism);
    }
    if (/^NM:/) {
      my ($field, $nm) = split /:\s*/;
      $nm =~ s/\|\S+\s*\S+\s*\S+\s*\S+//;
      $self->put_dot('refSeq',$nm);
    }
    if (/^NP:/) {
      my ($field, $np) = split /:\s*/;
      $np =~ s/\|\S+\s*\S+\s*\S+\s*\S+//;
      $self->put_dot( 'refSeq_Protein', $np);	
    }
    if (/^XM:/) {
      my ($field, $xm) = split /:\s*/;
      $xm =~ s/\|\S+\s*\S+\s*\S+\s*\S+//;
      $self->put_dot('refSeq_XM',$xm);
    }
    if (/^XP:/) {
      my ($field, $xp) = split /:\s*/;
      $xp =~ s/\|\S+\s*\S+\s*\S+\s*\S+//;
      $self->put_dot( 'refSeq_Protein_XP', $xp);	
    }
  
    if (/^ACCNUM:/) {
      my ($field, $acc) = split /:\s*/;
      if ($acc !~ /none/) {
	 my @acc=split (/\|/, $acc);
      my $tmp = $acc[0];
      $self->put_dot('Sequence_Accession', $tmp);
	}
    }	

    if (/^OFFICIAL_SYMBOL:/) {
      my ($field, $officialSymbol) = split /:\s*/;
	 if ($officialSymbol ne 'none' && $officialSymbol ne 'None' && $officialSymbol ne 'na') {
      $self->put_dot( 'Hugo', $officialSymbol);
	}
    }

    if (/^OFFICIAL_GENE_NAME:/) { 
      my ($field, $officialGeneName) = split /:\s*/;
      $self->put_dot( 'Official_GeneName', $officialGeneName);
    }
	
    if (/^ALIAS_SYMBOL:/) {
      my($field, $alias) = split /:\s*/;
 if ($alias ne 'none' && $alias ne 'None' && $alias ne
'na') {
      $self->put_dot('Alias_Symbol',$alias);
	}
    }

    if (/^STS:/) {
      my ($field, $chr, $sts, $other ) = split /\|/;
      $self->put_dot( 'STS', $sts);
    }
	
    if (/^PREFERRED_SYMBOL:/) {
	my ($field, $pref_symbol) = split /:\s*/;
	if ($pref_symbol ne 'none' && $pref_symbol ne 'None' && $pref_symbol ne
'na') {
     		if ($pref_symbol =~ /;/) {
                my @pref_symbol_array = split(/;/, $pref_symbol);
                        foreach my $tmp(@pref_symbol_array) {
			$self->put_dot( 'Prefered_Symbol', $tmp);
                        }
                }
                else {
		$self->put_dot( 'Prefered_Symbol', $pref_symbol);
                }
        }
    }

    if (/^PREFERRED_GENE_NAME:/) {
      my ($field, $pref_name) = split /:\s*/;
	if ($pref_name) {     
 $self->put_dot( 'Prefered_GeneName', $pref_name);}
    }
	
    if (/^OMIM:/) {
      my ($field, $OMIM) =split /:\s*/;
      $self->put_dot( 'OMIM', $OMIM);

    }

    if (/^PMID:/) {
	my ($field, $pubmid) = split /:\s*/;
	if (	$pubmid =~ /,/) {
		my @pubmid_array = split (/,/, $pubmid);
		foreach my $tmp (@pubmid_array) {
			$self->put_dot('PubMed', $tmp);
		}
	}
	else {
		$self->put_dot('PubMed', $pubmid);
	}
    }		
	
  }				#end of while
  return undef;
}				#end of sub

1;
