package Bio::DB::NextProt;

our $VERSION = '1.05';

use strict;
use warnings;
use REST::Client;
use Net::FTP::Tiny qw(ftp_get);


sub new {
	my ($class, @args) = @_;
	#my $self = $class->SUPER::new(@args);
	my $self = {};
	$self->{_client}		= REST::Client->new({host=> "http://www.nextprot.org", timeout => 10,});
	$self->{_query}			= undef;
	$self->{_filter}		= undef;
	$self->{_chromosome}	= undef;
	$self->{_format}		= "json";
	bless($self, $class);
	return $self;
}

sub search_protein() {
	
	my $self  = shift;
    my %param = @_;

	my $path = "/rest/protein/list";

    $self->{_format} = $param{'-format'} if defined $param{'-format'};

	if (defined $param{'-query'} && defined $param{'-filter'}) {
		
		$self->{_client}->GET($path."?query=".$param{'-query'}."&filter=".$param{'-filter'}."&format=".$self->{_format});

	} elsif (defined $param{'-query'}) {
		
		$self->{_client}->GET($path."?query=".$param{'-query'}."&format=".$self->{_format});

	} elsif (defined $param{'-filter'}) {
		
		$self->{_client}->GET($path."?filter=".$param{'-filter'}."&format=".$self->{_format});
	}

	&reset_params();

	return $self->{_client}->responseContent();

}

sub search_cv() {
	my $self  = shift;
	my %param = @_;
	
	my $path   = "/rest/cv/list";

    $self->{_format} = $param{'-format'} if defined $param{'-format'};

    if (defined $param{'-query'} && defined $param{'-filter'}) {

        $self->{_client}->GET($path."?query=".$param{'-query'}."&filter=".$param{'-filter'}."&format=".$self->{_format});

    } elsif (defined $param{'-query'}) {

        $self->{_client}->GET($path."?query=".$param{'-query'}."&format=".$self->{_format});

    } elsif (defined $param{'-filter'}) {

        $self->{_client}->GET($path."?filter=".$param{'-filter'}."&format=".$self->{_format});
    }

	&reset_params();

	return $self->{_client}->responseContent();

}

sub get_protein_info() {
	my $self  = shift;
	my %param = @_;

	my $path   = "/rest/entry/";

    $self->{_format} = $param{'-format'} if defined $param{'-format'};

	if (defined $param{'-query'} && $param{'-retrieve'}) {

		$self->{_client}->GET($path.$param{'-query'}."/".$param{'-retrieve'}."?format=".$self->{_format});

	} elsif (defined $param{'-query'}) {

		$self->{_client}->GET($path.$param{'-query'}."?format=".$self->{_format});
	}

	&reset_params();

	return $self->{_client}->responseContent();

}

sub get_isoform_info() {
	my $self  = shift;
	my %param = @_;

	my $path = "/rest/isoform/";

    $self->{_format} = $param{'-format'} if defined $param{'-format'};

    if (defined $param{'-query'} && $param{'-retrieve'}) {

        $self->{_client}->GET($path.$param{'-query'}."/".$param{'-retrieve'}."?format=".$self->{_format});

	} elsif (defined $param{'-query'}) {

	    $self->{_client}->GET($path.$param{'-query'}."?format=".$self->{_format});
	}

	&reset_params();

	return $self->{_client}->responseContent();

}

sub get_protein_cv_info() {
	my $self  = shift;
	my %param = @_;

	my $path = "/rest/cv/";

	$self->{_format} = $param{'-format'} if defined $param{'-format'};

	if (defined $param{'-query'} && $param{'-retrieve'}) {
		
		$self->{_client}->GET($path.$param{'-query'}."/".$param{'-retrieve'}."?format=".$self->{_format});

    } elsif (defined $param{'-query'}) {

        $self->{_client}->GET($path.$param{'-query'}."?format=".$self->{_format});
    }

	&reset_params();
    
	return $self->{_client}->responseContent();

}

sub get_accession_list() {
	my $self	= shift;
	my %param	= @_;

	my $path = "ftp://ftp.nextprot.org/pub/current_release/ac_lists";
	my @file = ();

	if ( defined $param{'-chromosome'} ) {

		$self->{_chromosome} = $param{'-chromosome'};
		my $chrom = $self->{_chromosome};

		if ($chrom eq "all") {
			@file = ftp_get($path."/"."nextprot_ac_list_all.txt");
		} else {
			@file = ftp_get($path."/"."nextprot_ac_list_chromosome_".$chrom.".txt");
		}

	} elsif ( defined $param{'-evidence'} ) {

		if ( $param{'-evidence'} eq "protein_level" ) {
			@file = ftp_get($path."/"."nextprot_ac_list_PE1_at_protein_level.txt");
		} elsif ( $param{'-evidence'} eq "transcript_level" ) {
			@file = ftp_get($path."/"."nextprot_ac_list_PE2_at_transcript_level.txt");
		} elsif ( $param{'-evidence'} eq "homology" ) {
			@file = ftp_get($path."/"."nextprot_ac_list_PE3_homology.txt")
		} elsif ( $param{'-evidence'} eq "predicted" ) {
			@file = ftp_get($path."/"."nextprot_ac_list_PE4_predicted.txt")
		} elsif ( $param{'-evidence'} eq "uncertain" ) {
			@file = ftp_get($path."/"."nextprot_ac_list_PE5_uncertain.txt")
		}
	}

	&reset_params();
	return @file;
}


sub get_hpp_report() {
	my $self	= shift;
	my %param	= @_;

	my $path = "ftp://ftp.nextprot.org/pub/current_release/custom/hpp";
	my @file = ();

	if ( defined $param{'-chromosome'} ) {

    	my $chrom = $param{'-chromosome'};
		@file = ftp_get($path."/"."HPP_chromosome_".$chrom.".txt");

	} elsif ( defined $param{'-phospho'} ) {
		@file = ftp_get($path."/"."HPP_entries_with_phospho_by_chromosome.txt");
	} elsif ( defined $param{'-nacetyl'} ) {
		@file = ftp_get($path."/"."HPP_entries_with_nacetyl_by_chromosome.txt");
	}

	&reset_params();
	return @file;
		
}


sub get_mapping() {
	my $self	= shift;
	my %param	= @_;

	my $path = "ftp://ftp.nextprot.org/pub/current_release/mapping";
	my @file = ();

	if ( defined $param{'-map'} ) {
		my $db = $param{'-map'};

		if ( $db eq 'ensembl_gene' ) {
			@file = ftp_get($path."/"."nextprot_ensg.txt");
		} elsif ( $db eq 'ensembl_protein' ) {
			@file = ftp_get($path."/"."nextprot_ensp.txt");
		} elsif ( $db eq 'ensembl_unmapped' ) {
			@file = ftp_get($path."/"."nextprot_ensp_unmapped.txt");
		} elsif ( $db eq 'ensembl_transcript' ) {
			@file = ftp_get($path."/"."nextprot_enst.txt");
		} elsif ( $db eq 'ensembl_transcript_unmapped' ) {
			@file = ftp_get($path."/"."nextprot_enst_unmapped.txt");
		} elsif ( $db eq 'geneid' ) {
			@file = ftp_get($path."/"."nextprot_geneid.txt");
		} elsif ( $db eq 'hgnc' ) {
			@file = ftp_get($path."/"."nextprot_hgnc.txt");
		} elsif ( $db eq 'mgi' ) {
			@file = ftp_get($path."/"."nextprot_mgi.txt");
		} elsif ( $db eq 'refseq' ) {
			@file = ftp_get($path."/"."nextprot_refseq.txt");
		}
	}
	
	&reset_params();
	return @file;

}

sub get_chromosome() {
	my $self  =	shift;
	my %param =	@_;

	my @data  = ();
	my %table = ();

	my $path = "ftp://ftp.nextprot.org/pub/current_release/chr_reports";

	if ( defined $param{'-chromosome'} ) {

		$self->{_chromosome} = $param{'-chromosome'};
		my $chrom = $self->{_chromosome};
		my $file = ftp_get($path."/"."nextprot_"."chromosome_".$chrom.".txt");
		my @data = split /^/m, $file;

		for my $prot (@data) {
			chomp $prot;

			if ($prot =~ m/^[A-Za-z|0-9\-]+\s+NX/) {
				
				$prot =~ s/\s{2,}/\t/g;
				my @temp = split(/\t/, $prot);

				#if (exists $table{$temp[1]}) {
				#	print "redundancy detected: $temp[1]\n";
				#}

				$table{$temp[1]} = {
					gene_name		=>  $temp[0],
					position        =>  $temp[2],
					start_position  =>  $temp[3],
					stop_position   =>  $temp[4],
					existence       =>  $temp[5],
					proteomics      =>  $temp[6],
					antibody        =>  $temp[7],
					has_3d          =>  $temp[8],
					disease         =>  $temp[9],
					isoforms        =>  $temp[10],
					variants        =>  $temp[11],
					ptms            =>  $temp[12],
					description     =>  $temp[13],
				}

			}
		}

	}

	&reset_params();

	return %table;
}

sub mapping {
    my $self    = shift;
    my $target  = shift;
    
    my $path = 'ftp://ftp.nextprot.org/pub/current_release/mapping/nextprot_';
    my $file = ftp_get($path.$target.".txt");
    my @data = split(/\n/, $file);

    my %map;

    for my $pair ( @data ) {
        
        chomp $pair;
        my ($key, $value) = split(/\t/, $pair);
        $map{$key} = $value;
    }

    return %map;
}

sub reset_params() {
	my $self = shift;

	$self->{_query}  = undef;
	$self->{_filter} = undef;
}

1;
