package Bio::ConnectDots::ConnectorSet::Uniprot;

use strict;
use vars qw(@ISA);
use Bio::ConnectDots::ConnectorSet;
@ISA = qw(Bio::ConnectDots::ConnectorSet);

sub parse_entry {
	my ($self) = @_;
	my $input_fh = $self->input_fh;

	while (<$input_fh>) {
		chomp;
		if (/^\/\//) {
			next unless $self->have_dots;
			return 1;
		}    #end of if
		if (/^ID/) {
			my ( $field, $SP_entry_id, $others ) = split /\s+/;
			$self->put_dot( 'SwissProtEntryName', $SP_entry_id );
		}
		if (/^AC/) {
			my ( $field, $SwissProt ) = split /\s+/;
			chop($SwissProt);
			$self->put_dot( 'SwissProt', $SwissProt );
		}

   # important that this comes before any entries in the entry that are after DE
		if (/^DE/) {
			my ( $field, $desc ) = /(^DE)\s+(.*)$/;
			my $cont = 1;
			while ($cont) {
				$_ = <$input_fh>;
				if (/^DE/) {
					my ( $label, $desc_more ) = /(^DE)\s+(.*)$/;
					$desc .= " $desc_more";
				}
				else { $cont = 0; }
			}
			$self->put_dot( 'Protein_Desc', $desc );
		}
		if (/^OS/) {
			my ( $field, $Organism ) = /(^OS)\s+(.*)$/;
			chop($Organism);
			$self->put_dot( 'Organism', $Organism );
		}
		if (/^OX/) {
			my ( $field, $taxID ) = split /\s+/;
			chop($taxID);
			$self->put_dot( 'NCBI_taxID', $taxID );
		}

		if (/^RX/) {
			my @RX = split /\s+/;
			for my $rx (@RX) {
				$rx =~ s/;//;
				if ( $rx =~ /MEDLINE/ ) {
					my ( $tmp, $medline ) = split( '=', $rx );
					$self->put_dot( 'MEDLINE', $medline );
				}
				if ( $rx =~ /PubMed/ ) {
					my ( $tmp, $pubmed ) = split( '=', $rx );
					$self->put_dot( 'PubMed', $pubmed );
				}
			}
		}

		if (/^CC.*-!- FUNCTION:/) {
			my $function =~ /^CC.*-!- FUNCTION:\s*(.*)/;
			my $cont = 1;
			while ($cont) {
				$_ = <$input_fh>;
				chomp;
				if (/^CC/ && !/^CC\s+-!-/) {
					my $more = /^CC\s+(.*)$/;
					$function .= " $more";
				}
				else { $cont = 0; }
			}
			$self->put_dot( 'Function', $function );
		}
		if (/^CC.*-!- CATALYTIC ACTIVITY:/) {
			my $catyl =~ /^CC.*-!- CATALYTIC ACTIVITY:\s*(.*)/;
			my $cont = 1;
			while ($cont) {
				$_ = <$input_fh>;
				chomp;
				if (/^CC/ && !/^CC\s+-!-/) {
					my $more = /^CC\s+(.*)$/;
					$catyl .= " $more";
				}
				else { $cont = 0; }
			}
			$self->put_dot( 'Catalytic_Activity', $catyl );
		}
		if (/^CC.*-!- SUBUNIT:/) {
			my $subunit =~ /^CC.*-!- SUBUNIT:\s*(.*)/;
			my $cont = 1;
			while ($cont) {
				$_ = <$input_fh>;
				chomp;
				if (/^CC/ && !/^CC\s+-!-/) {
					my $more = /^CC\s+(.*)$/;
					$subunit .= " $more";
				}
				else { $cont = 0; }
			}
			$self->put_dot( 'Subunit', $subunit );
		}
		if (/^CC.*-!- TISSUE SPECIFICITY:/) {
			my $tissue =~ /^CC.*-!- TISSUE SPECIFICITY:\s*(.*)/;
			my $cont = 1;
			while ($cont) {
				$_ = <$input_fh>;
				chomp;
				if (/^CC/ && !/^CC\s+-!-/) {
					my $more = /^CC\s+(.*)$/;
					$$tissue .= " $more";
				}
				else { $cont = 0; }
			}
			$self->put_dot( 'Tissue', $tissue );
		}

		if (/^DR/) {
			my @DR = split /\s+/;
			if ( $DR[1] eq 'EMBL;' ) {
				chop( $DR[2] );
				$self->put_dot( 'EMBL_mRNA_protein', $DR[2] );
			}
			if ( $DR[1] eq 'PIR;' ) {
				chop( $DR[2] );
				$self->put_dot( 'PIR', $DR[2] );
			}
			if ( $DR[1] eq 'InterPro;' ) {
				chop( $DR[2] );
				$self->put_dot( 'InterPro', $DR[2] );
			}
			if ( $DR[1] eq 'pfam;' ) {
				chop( $DR[2] );
				$self->put_dot( 'pfam', $DR[2] );
			}
			if ( $DR[1] eq 'TIGRFAMs;' ) {
				chop( $DR[2] );
				$self->put_dot( 'TIGRFAMs', $DR[2] );
			}

		}
		
		if (/^KW/) {
			chomp;
			my ($keywords) =~ /^KW\s*(.*)/;
			my $cont = 1;
			while ($cont) {
				$_ = <$input_fh>;
				chomp;
				if (/^KW/) {
					my ($more) = /^KW\s+(.*)$/;
					$keywords .= " $more";
				}
				else { $cont = 0; }
			}
			$self->put_dot( 'Keywords', $keywords );

		}
		
		if (/^GN/) {
			chomp;
			my ($gene_name, $alias) =~ /^GN\s+Name=(.+);\s+Synonyms=(.+);/;	
			$self->put_dot( 'Gene_Name', $gene_name);
			$self->put_dot( 'Alias_Symbol', $alias);
		}
		
		if (/^\/\//) {
			next unless $self->have_dots;
			return 1;
		}    #end of if

	}    #end of while
	return undef;
}    #end of sub

1;
