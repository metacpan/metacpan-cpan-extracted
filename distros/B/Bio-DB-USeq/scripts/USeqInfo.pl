#!/usr/bin/perl 

use warnings;
use strict;
use Getopt::Long;
use Pod::Usage;
use Bio::DB::USeq;

my $VERSION = '0.23';

### Quick help
unless (@ARGV) { 
	# when no command line options are present
	# print SYNOPSIS
	pod2usage( {
		'-verbose' => 0, 
		'-exitval' => 1,
	} );
}



### Get command line options and initialize values
my (
	$do_chrom,
	$do_stats,
	$help,
	$print_version,
);

# Command line options
GetOptions( 
	'chrom!'    => \$do_chrom, # print chromosome information
	'stat!'     => \$do_stats, # print statistics
	'help'      => \$help, # request help
	'version'   => \$print_version, # print the version
) or die " unrecognized option(s)!! please refer to the help documentation\n\n";

# Print help
if ($help) {
	# print entire POD
	pod2usage( {
		'-verbose' => 2,
		'-exitval' => 1,
	} );
}

# Print version
if ($print_version) {
	print " USeqInfo.pl, version $VERSION\n\n";
	exit;
}




### Process files
foreach my $file (@ARGV) {
	
	# check extension
	unless ($file =~ /\.useq$/i) {
		warn "$file does not have a .useq extension. skipping\n";
		next;
	}
	process_file($file);
}
exit;






############ Subroutines ###################

sub process_file {
	my $file = shift;
	
	my $useq = Bio::DB::USeq->new($file) or return;
	
	# Basic metadata
	print "$file\n";
	printf "  versioned genome: %s\n", $useq->genome;
	printf "  data type: %s\n", $useq->type;
	printf "  graph style: %s\n", $useq->attribute('initialGraphStyle') || q( );
	printf "  creation date: %s\n", $useq->attribute('archiveCreationDate') || q( );
	printf "  original data: %s\n", $useq->attribute('originatingDataSource') || q( );
	printf "  description: %s\n", $useq->attribute('description') || q(none);
	printf "  stranded: %s\n", $useq->stranded ? 'yes' : 'no';
	my @seqs = $useq->seq_ids;
	printf "  number chromosomes: %s\n", scalar(@seqs);
	
	# slice information
	my @slices = $useq->slices;
	printf "  number slices: %s\n", scalar(@slices);
	my $obs_number = 0;
	foreach (@slices) {
		$obs_number += $useq->slice_obs_number($_);
	}
	print "  number observations: $obs_number\n";
	
	# observation type
	my $obs_type = "chromosome, ";
	if ($useq->slice_type( $slices[0] ) =~ /^[is][is]/) {
		$obs_type .= "start, stop";
	}
	else {
		$obs_type .= "position";
	}
	if ($useq->slice_type( $slices[0] ) =~ /f/) {
		$obs_type .= ", score";
	}
	if ($useq->slice_type( $slices[0] ) =~ /t/) {
		$obs_type .= ", text";
	}
	print "  observations include: $obs_type\n";
	
	# chromosome and statistics information
	if ($do_chrom and $do_stats) {
		print "  chromosome length min mean stdev max\n";
		my $global_stats = $useq->global_stats;
		my $genome_length = 0;
		foreach (@seqs) {
			my $stats = $useq->chr_stats($_);
			printf "   $_ %s %0.3f %0.3f %0.3f %0.3f\n", $useq->length($_), 
				$stats->{minVal}, $useq->chr_mean($_), $useq->chr_stdev($_), 
				$stats->{maxVal};
			$genome_length += $useq->length($_);
		}
		printf "   genome $genome_length %0.3f %0.3f %0.3f %0.3f\n", 
			$global_stats->{minVal}, $useq->global_mean, $useq->global_stdev, 
			$global_stats->{maxVal};
	}
	elsif ($do_chrom) {
		print "  chromosome length:\n";
		foreach (@seqs) {
			printf "   $_ %s\n", $useq->length($_);
		}
	}
	elsif ($do_stats) {
		my $global_stats = $useq->global_stats;
		print "  genome scores: min mean stdev max\n";
		printf "   %0.3f %0.3f %0.3f %0.3f\n", 
			$global_stats->{minVal}, $useq->global_mean, $useq->global_stdev, 
			$global_stats->{maxVal};
	}
	
	return;
}







__END__

=head1 NAME

USeqInfo.pl

A script to collect basic information about a USeq archive.

=head1 SYNOPSIS

USeqInfo.pl [--options...] <file1.useq> <file2.useq ...>
  
  Options:
  -c | --chrom
  -s | --stat
  -v | --version
  -h | --help

=head1 OPTIONS

The command line flags and descriptions:

=over 4

=item --chrom

Print each of the chromosome names and their lengths.

=item --stat

Print statistics for the scores across the genome, including mean, 
standard deviation, minimum, and maximum values. If the chromosomes 
are printed also, then chromosome level statistics are printed as well.

=item --version

Print the version number.

=item --help

Display this POD documentation.

=back

=head1 DESCRIPTION

This program will present basic information about a USeq archive. 
Basic metadata from the internal F<archiveReadMe.txt> is listed, 
including genome version, data type, graph type, description, source 
data, and date, as well as additional information about the chromosomes, 
slices, observations, and content. 

If desired, chromosome information, including name and length, may also be 
presented.

If the archive includes score data, it may also optionally present basic 
statistics across the genome, including mean, standard deviation, minimum, 
and maximum values. If chromosome information is also presented, then 
chromosome level statistics are included as well. Note that this may take 
extra time to calculate, as the entire file must be read. If the archive 
file is writable by the user, then chromosome and genome statistics are 
automatically updated in the F<archiveReadMe.txt> file, avoiding future 
calculations. 

=head1 AUTHOR

 Timothy J. Parnell, PhD
 Dept of Oncological Sciences
 Huntsman Cancer Institute
 University of Utah
 Salt Lake City, UT, 84112

This package is free software; you can redistribute it and/or modify
it under the terms of the Artistic License 2.0.  
