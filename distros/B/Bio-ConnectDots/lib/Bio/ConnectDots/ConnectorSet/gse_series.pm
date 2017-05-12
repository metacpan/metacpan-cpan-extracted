package Bio::ConnectDots::ConnectorSet::gse_series;
use strict;
use vars qw(@ISA);
use Bio::ConnectDots::ConnectorSet;
@ISA = qw(Bio::ConnectDots::ConnectorSet);

sub parse_entry {
  	my ($self) = @_;
  	my $input_fh=$self->input_fh;
  	#the file start with line with index number 1 
  	my $flag = 0;
  	while (<$input_fh>) {
		chomp;
		s/[\r\n]//;
		if (/^\^series\s*=\s*(GSE\d+)/) {
			my $gse = $1;
			$flag = 1;
			$self->put_dot("SeriesID","$gse") if $gse;
		}
		if (/^\!Series_status\s*=\s*(.*)/) {
			my $status = $1;
			$self->put_dot("Status","$status") if $status;
		}
		if (/^\!Series_title\s*=\s*(.*)/) {
			my $title = $1;	
			$self->put_dot("Title","$title") if $title;
		}
		if (/^\!Series_type\s*=\s*(.*)/) {
			my $type = $1;
			$self->put_dot("Type","$type") if $type;
		}
		if (/^\!Series_pubmed_id\s*=\s*(\d+)/) {
			my $pubmed = $1;
			$self->put_dot("PubMedID","$pubmed")if $pubmed;
		}
		if (/^\!Series_web_link\s*=\s*(.*)/) {
			my $link = $1;
			$self->put_dot("Link","$link") if $link;
		}
		if (/^\!Series_description\s*=\s*(.*)/) {
			my $desc = $1;
			$self->put_dot("Description","$desc") if $desc;
		}
		if (/^\!Series_keyword\s*=\s*(.*)/) {
			my $key = $1;
			$self->put_dot("Keyword","$key") if $key;
		}
		if (/^\!Series_sample_id\s*=\s*(GSM\d+)/) {
			my $samp = $1;
			$self->put_dot("SampleID","$samp") if $samp;
		}
		if (/^\^platform\s*=\s*(GPL\d+)/) {
			return $self->have_dots if $flag;
			$flag = 0;
		}		
	}
	return undef;
}
