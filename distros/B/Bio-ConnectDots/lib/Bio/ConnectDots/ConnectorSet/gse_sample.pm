package Bio::ConnectDots::ConnectorSet::gse_sample;
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
		s/\t/\s/;
		chomp;
		if (/^\^sample\s*=\s*(GSM\d+)/) {
			my $sample = $1;
			$self->put_dot("SampleID","$sample") if $sample;
		}
		if (/^\!Sample_status\s*=\s*(.*)/) {
			my $status = $1;
			$self->put_dot("Status","$status") if $status;
		}
		if (/^\!Sample_title\s*=\s*(.*)/) {
			my $title = $1;
			$self->put_dot("Title","$title") if $title;
		}
		if (/^\!Sample_type\s*=\s*(.*)/) {
			my $type = $1;
			$self->put_dot("Type","$type") if $type;
		}
		if (/^\!Sample_pubmed_id\s*=\s*(\d+)/) {
			my $pubmed = $1;
			$self->put_dot("PubMedID","$pubmed") if $pubmed;
		}
		if (/^\!Sample_web_link\s*=\s*(.*)/) {
			my $link = $1;
			$self->put_dot("Link","$link") if $link;
		}
		if (/^\!Sample_description\s*=\s*(.*)/) {
			my $desc = $1;
			## removed b/c was causing copy error
			#$self->put_dot("Description","$desc") if $desc;
		}
		if (/^\!Sample_keyword\s*=\s*(.*)/) {
			my $key = $1;
			$self->put_dot("Keyword","$key") if $key;
		}
		if (/^\!Sample_organism\s*=\s*(.*)/) {
			my $org = $1;
			$self->put_dot("Organism","$org") if $org;
		}
		if (/^\!Sample_lot_batch\s*=\s*(.*)/) {
			my $lot = $1;
			$self->put_dot("Lot","$lot") if $lot;
		}
		if (/^\!Sample_platform_id\s*=\s*(GPL\d+)/) {
			my $gpl = $1;
			$self->put_dot("PlatformID","$gpl") if $gpl;
		}
		if (/^\!Sample_target_source\s*=\s*(.*)/) {
			my $source = $1;
			$self->put_dot("TargetSource","$source") if $source;
		}
		if (/^\!Sample_geo_accession\s*=\s*(GSM\d+)/) {
			return $self->have_dots;
		}
	}
	close GSE;
}