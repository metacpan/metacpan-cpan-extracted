package Bio::ConnectDots::ConnectorSet::gse_platform;
use strict;
use vars qw(@ISA);
use Bio::ConnectDots::ConnectorSet;
@ISA = qw(Bio::ConnectDots::ConnectorSet);


sub parse_entry {
  	my ($self) = @_;
  	my $input_fh=$self->input_fh;
  	while (<$input_fh>) {
		chomp;
		s/[\r\n]//;
		if (/\^platform\s*=\s*(GPL\d+)/) {
			my $plat = $1;
			$self->put_dot("PlatformID","$plat") if $plat;
		}
		if (/\!Platform_status\s*=\s*(.*)/) {
			my $status = $1;
			$self->put_dot("Status","$status") if $status;
		}
		if (/\!Platform_title\s*=\s*(.*)/) {
			my $title = $1;
			$self->put_dot("Title","$title") if $title;
		}
		if (/\!Platform_type\s*=\s*(.*)/) {
			my $type = $1;
			$self->put_dot("Type","$type") if $type;
		}
		if (/\!Platform_description\s*=\s*(.*)/) {
			my $desc = $1;
			$self->put_dot("Description","$desc") if $desc;
		}
		if (/\!Platform_keyword\s*=\s*(.*)/) {
			my $key = $1;
			$self->put_dot("Keyword","$key") if $key;
		}
		if (/\!Platform_organism\s*=\s*(.*)/) {
			my $org = $1;
			$self->put_dot("Organism","$org") if $org;
		}
		if (/\!Platform_geo_accession\s*=\s*(GPL\d+)/) {
			return $self->have_dots;
		}
	}
	close GSE;
}