package Bio::ConnectDots::ConnectorSet::ENZYME;

# parser for ENZYME database file at:
# ftp://au.expasy.org/databases/enzyme/release_with_updates/enzyme.dat

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
			my ( $field, $ECnumber ) = split /\s+/;
			$self->put_dot( 'ECnumber', $ECnumber );
		}

		if (/^DE/) {
			/^DE\s+(.+)/;
			my $gene_name = $1;
			chomp($gene_name);
			$self->put_dot( 'Official_GeneName', $gene_name );
		}    #end if DE

		if (/^AN/) {
			/^AN\s+(.+)/;
			my $alt_name = $1;
			chomp($alt_name);
			$self->put_dot( 'Alias_Symbol', $alt_name );
		}

		if (/^PR/) {
			my @PR = split /\s+/;
			if ( $PR[1] eq 'PROSITE;' ) {
				chop( $PR[2] );
				$PR[2] =~ s/;$//g;
				$self->put_dot( 'PROSITE', $PR[2] );
			}
		}    # end of PR

		if (/^DR/) {
			s/^DR\s+//;    # remove ident
			s/\s+//g;      # remove whitespace
			my @DR = split /[,;]/;
			my $i  = 0;
			while ( $DR[$i] ) {
				my $ac_num = @DR[$i];
				chomp($ac_num);
				$ac_num =~ s/-\d//g;
				$self->put_dot( 'SwissProt', $ac_num );
				$i += 2;    # skip over Entry_name (i.e. GPD2_YEAST;)
			}
		}    #if DR
	}    #end of while
	return undef;
}    #end of sub

1;
