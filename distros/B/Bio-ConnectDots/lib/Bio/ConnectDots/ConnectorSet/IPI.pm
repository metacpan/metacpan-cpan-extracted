package Bio::ConnectDots::ConnectorSet::IPI;

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
			my ( $field, $IPI, $others ) = split /\s+/;
			$self->put_dot( 'IPI_id', $IPI );
			$IPI =~ s/\.[0123456789]$//;
			$self->put_dot( 'IPI_id_old', $IPI );
		}
		if (/^AC/) {
			my ( $field, @retired ) = split /\s+/;
			foreach my $id (@retired) {
				$id =~ s/;//g;
				$self->put_dot( 'Retired_id', $id );
			}
		}
		if (/^DE/) {
			my ( $field, $prot_name ) = /(^DE)\s+(.+)$/;
			$prot_name =~ s/.$//;
			$self->put_dot( 'Protein_Name', $prot_name );
		}
		if (/^OS/) {
			$_ =~ /^OS\s+(\w+\s+\w+)\s+\(.+\)\./;
			my $organism = $1;
			$self->put_dot( 'Organism', $organism );
		}
		if (/^OX/) {
			my ( $field, $TaxID ) = split /\s+/;
			$TaxID =~ s/NCBI_TaxID=//g;
			$TaxID =~ s/;//g;
			$self->put_dot( 'NCBI_taxID', $TaxID );
		}

		if (/^DR/) {
			my @DR = split /\s+/;
			if ( $DR[1] eq 'REFSEQ_XP;' ) {
				chop( $DR[2] );
				$DR[2] =~ s/;$//g;
				$self->put_dot( 'REFSEQ_XP', $DR[2] );

				if ( $DR[3] =~ /GI:/ ) {
					$DR[3] =~ s/^GI://g;
					$DR[3] =~ s/;$//g;
					$self->put_dot( 'GI', $DR[3] );
				}
			}
			if ( $DR[1] eq 'PRINTS;' ) {
				chop( $DR[2] );
				$DR[2] =~ s/;//g;
				$self->put_dot( 'PRINTS', $DR[2] );
			}
			if ( $DR[1] eq 'InterPro;' ) {
				chop( $DR[2] );
				$DR[2] =~ s/;//g;
				$self->put_dot( 'InterPro', $DR[2] );
			}
			if ( $DR[1] eq 'Pfam;' ) {
				chop( $DR[2] );
				$DR[2] =~ s/;//g;
				$self->put_dot( 'pfam', $DR[2] );
			}
			if ( $DR[1] eq 'ProDom;' ) {
				chop( $DR[2] );
				$DR[2] =~ s/;//g;
				$self->put_dot( 'ProDom', $DR[2] );
			}
			if ( $DR[1] eq 'SMART;' ) {
				chop( $DR[2] );
				$DR[2] =~ s/;//g;
				$self->put_dot( 'SMART', $DR[2] );
			}
			if ( $DR[1] eq 'PROSITE;' ) {
				chop( $DR[2] );
				$DR[2] =~ s/;//g;
				$self->put_dot( 'PROSITE', $DR[2] );
			}
			if ( $DR[1] eq 'HUGO;' ) {
				chop( $DR[3] );
				$DR[3] =~ s/;//g;
				$self->put_dot( 'HUGO', $DR[3] );
			}
			if ( $DR[1] eq 'LocusLink;' ) {
				chop( $DR[2] );
				$DR[2] =~ s/;//g;
				$self->put_dot( 'LocusLink', $DR[2] );
			}
			if ( $DR[1] eq 'GO;' ) {
				chop( $DR[2] );
				$DR[2] =~ s/;//g;
				$self->put_dot( 'GO_id', $DR[2] );
			}
			if ( $DR[1] eq 'UniProt/Swiss-Prot;' ) {
				chop( $DR[2] );
				$DR[2] =~ s/;//g;
				$DR[2] =~ s/-\d//g;
				$self->put_dot( 'SwissProt', $DR[2] );
			}
			if ( $DR[1] eq 'REFSEQ_NP;' ) {
				chop( $DR[2] );
				$DR[2] =~ s/;$//g;
				$self->put_dot( 'REFSEQ_NP', $DR[2] );

				if ( $DR[3] =~ /GI:/ ) {
					$DR[3] =~ s/^GI://g;
					$DR[3] =~ s/;$//g;
					$self->put_dot( 'GI', $DR[3] );
				}
			}
			if ( $DR[1] eq 'UniProt/TrEMBL;' ) {
				/^DR\s+UniProt\/TrEMBL;\s*(.*)$/;
				$self->put_dot( 'TREMBL', $1 );
			}
			if ( $DR[1] eq 'TIGRFAMs;' ) {
				chop( $DR[2] );
				$DR[2] =~ s/;//g;
				$self->put_dot( 'TIGRFAMs', $DR[2] );
			}
			if ( $DR[1] eq 'ENSEMBL;' ) {
				chop( $DR[2] );
				$DR[2] =~ s/;$//g;
				$self->put_dot( 'ENSEMBL_peptide', $DR[2] );

				$DR[3] =~ s/;$//g;
				$self->put_dot( 'ENSEMBL_gene', $DR[3] );
			}
			if ( $DR[1] eq 'RZPD;' ) {
				/^DR\s+RZPD;\s*(.*)$/;
				$self->put_dot( 'RZPD', $1 );
			}
			if ( $DR[1] eq 'Genew;' ) {
				/^DR\s+Genew;\s*(.*)$/;
				$self->put_dot( 'Genew', $1 );
			}
		}    #if DR
		if (/^SQ/) {
			my @SQ = split /\s+/;
			$self->put_dot( 'AA_length',        $SQ[2] );
			$self->put_dot( 'Molecular_Weight', $SQ[4] );

#			# process sequence
#			my $cont = 1;
#			my $sequence;
#			while ($cont) {
#				$_ = <$input_fh>; 
#				chomp;
#				if (/^\s+/) {
#					s/\s//g; # remove white spaces between sets of 10 AAs
#					$sequence .= $_; 
#				}
#				else { $cont = 0; }
#			}
#			$self->put_dot( 'Protein_Sequence', $sequence );
#			if (/^\/\//) {
#				next unless $self->have_dots;
#				return 1;
#			}	
		} # end SQ
	}    #end of while
	return undef;
}    #end of sub

1;
