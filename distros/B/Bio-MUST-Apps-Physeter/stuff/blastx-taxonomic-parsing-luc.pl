#!/usr/bin/env perl

use Modern::Perl '2011';
use autodie;
use Smart::Comments '###';

use File::Basename;
use Statistics::Descriptive;
use LWP::Simple 'get';
use Path::Class 'file';
use Getopt::Euclid qw(:vars);

use Bio::MUST::Core;
use aliased 'Bio::MUST::Core::Taxonomy';

#TODO
#modifier le mode list contaminants
#ajouter HGT avec coverage
#ajouter clean fasta


###build taxonomy object
my $taxdir = $ARGV{'--taxdir'};
my $tax = Taxonomy->new(
    tax_dir   => $taxdir,
);

#get list of contaminants to analyse
my @clists;

my $contamlists = $ARGV{'--contam-list'};
open my $clist, '<', $contamlists;
while (my $line = <$clist>) {
	chomp $line;
	push @clists, $line;
}

#open general outfiles
my $outfile = "blastx_$ARGV{'--length'}-$ARGV{'--identity'}-$ARGV{'--bitscore'}.result";
open my $out, '>', $outfile;
my $detail = "blastx_$ARGV{'--length'}-$ARGV{'--identity'}-$ARGV{'--bitscore'}.detail";
open my $det, '>', $detail;
print_deflines($out, $det, \@clists);


###parse file
my $loop_control;
for my $infile (@ARGV_infiles) {
	$loop_control++;
	#declare 
	my $assembly = $infile;
	my $deflinenumber;
	my %count_of;
	
	#get extension of file
	my $blast_ext = $ARGV{'--blast-extension'};
	$assembly =~ s/$blast_ext//g;
	
	#take the number of deflines in original fasta file
	my $fasta_ext = $ARGV{'--fasta-extension'};
	my $fasta = "$assembly$fasta_ext";
	open my $file1, '<', $fasta;
	while (my $line = <$file1>) {
		chomp $line;
		$deflinenumber++  if $line =~ /\>/;
	}
	
	#define organism for future skip on self-hit
	my @taxonomy = $tax->get_taxonomy($assembly);
	my $current_org = pop @taxonomy;
	
	#read blastx report file
	open my $report, '<', $infile;
	my $previous_hit = "NA";
	my $previous_read = 'NA';
	my $read = 'NA';
	my $bit_threshold = 0;
	my @bithits;
	
	LINE:
	while (my $line = <$report>) {
		chomp $line;
		my @chunks = split /\t/, $line;
		
		#skip duplicate hit part
		my $id = $chunks[1];
		next LINE if $previous_hit eq $id;
		$previous_hit = $id;
		
		#bitscore threshold part
		my $previous_read = $read;
		$read = $chunks[0];
		#first occurence of a read, define threshold value
		if ($previous_read ne $read) {
			#theshold on the hit number to compute LCA
			my $countof = LCA_compute(\@bithits, $ARGV{'--min-hit'}, $tax, $ARGV{'--query-org'}, \%count_of, \@clists);
			%count_of = %{$countof};
			@bithits = ();
			#reset bitscore threshold
			$bit_threshold = 0;
			
			#Skip self match, assume self match only on first hit
			my $taxid = $id;
			$taxid =~ s/\|\S+//;
			my $skip = skip_self($taxid, $tax, $current_org);
			next LINE if ($skip eq 'skip');
			
			#first occurence of the read, assume best bitscore in first hit
			my $identity = $chunks[2];
			my $length = $chunks[3];
			if (($length >= $ARGV{'--length'}) || ($identity >= $ARGV{'--identity'})) {
				my $bitscore = $chunks[11];
				$bit_threshold = $ARGV{'--bitscore'} * $bitscore;
				#take hit
				push @bithits, $taxid;
			}
		}
		#process bitscore threshold when it's not first occurence of a read
		if (($previous_read eq $read) && ($bit_threshold > 0)) {
			my $bitscore = $chunks[11];
			if ($bitscore >= $bit_threshold) { 
				#take hit
				my $taxid = $id;
				$taxid =~ s/\|\S+//;
				push @bithits, $taxid;
			}
		}
	}
	#load hit if end of file
	my $countof = LCA_compute(\@bithits, $ARGV{'--min-hit'}, $tax, $ARGV{'--query-org'}, \%count_of, \@clists);
	%count_of = %{$countof};
	@bithits = ();
	
	#print result
	print_result($assembly, $ARGV{'--query-org'}, \%count_of, $deflinenumber, $out, $det, \@clists);
	
}

#Function part

sub LCA_compute {
	my @bithits = @{$_[0]};
	my $min_hit = $_[1];
	my $tax = $_[2];
	my $query = $_[3];
	my %count_of = %{$_[4]};
	my @clists = @{$_[5]};
	
	if (@bithits >= $min_hit) {
		#LCA labelling
		my @seqids;
		for my $hit (@bithits) {
			push @seqids, $hit . '|1';
		}
		my @ancestors = $tax->get_common_taxonomy_from_seq_ids(@seqids);
		if (@ancestors >= 1) {
			my $Alineage = join '; ', @ancestors;
			my $lasttaxa = pop @ancestors;
			if ($Alineage =~ m/$query/) {
				#query part
				$count_of{LCA}{$query}++;
			}
			elsif (($lasttaxa eq 'cellular organisms') || ($lasttaxa eq 'Bacteria') || ($lasttaxa eq 'Terrabacteria group')) {
				#unkown part
				$count_of{LCA}{unknown}++;
			}
			else {
				#contam part
				$count_of{LCA}{contam}++;
				my $found = 0;
				CONT:
				for my $contaminant (@clists) {
					if ($Alineage =~ m/$contaminant/) {
						$count_of{LCA}{$contaminant}++;
						$found++;
						#register contaminant
						last CONT;
					}
				}
				$count_of{LCA}{others}++ unless $found > 0;
			}
		}
	}
	
	return (\%count_of);
}

sub print_result {
	my $assembly = $_[0];
	my $query = $_[1];	
	my %count_of = %{$_[2]};
	my $deflinenumber = $_[3];
	my $out = $_[4];
	my $det = $_[5];
	my @clists = @{$_[6]};
	
	print {$out} $assembly
		. "\t" . (($count_of{LCA}{$query}/$deflinenumber) * 100) 
		. "\t" . (($count_of{LCA}{contam}/$deflinenumber) * 100) 
		. "\t" . (($count_of{LCA}{unknown}/$deflinenumber) * 100)
		. "\t" . ((($deflinenumber - $count_of{LCA}{contam} - $count_of{LCA}{$query} - $count_of{LCA}{unknown})/$deflinenumber) * 100) 
		. "\n";
	
	print {$det} $assembly . "\t" . (($count_of{LCA}{$query}/$deflinenumber) * 100) . "\t";
	for my $contaminant (@clists) {
		print{$det} ( ($count_of{LCA}{$contaminant} // 0) / $deflinenumber * 100). "\t";
	}
	print{$det} (($count_of{LCA}{others}/$deflinenumber) * 100) . "\t" . (($count_of{LCA}{unknown}/$deflinenumber) * 100) 
		. "\t" . ((($deflinenumber - $count_of{LCA}{contam} - $count_of{LCA}{$query} - $count_of{LCA}{unknown})/$deflinenumber) * 100) 
		. "\n";
	
}

sub print_deflines {
	my $out = $_[0];
	my $det = $_[1];
	my @clists = @{$_[2]};
	
	#output for level of contaminations
	print {$out} "assembly" . "\t" . "LCA$ARGV{'--query-org'}" . "\t" . "LCAcontam" . 
	"\t" . "LCAunkown" . "\t" . "LCAunmatch" . "\n";
	#output for detail of contaminants
	print{$det} "assembly" . "\t" . $ARGV{'--query-org'} . "\t";
	for my $contaminant (@clists) {
		print{$det} $contaminant . "\t";
	}
	print{$det} "others" . "\t" . "unknown" . "\t" . "unmatch". "\n";
}

sub skip_self {
	my $taxid = $_[0];
	my $tax = $_[1];
	my $current_org = $_[2];
	
	my @taxonomy = $tax->get_taxonomy($taxid);
	my $org = pop @taxonomy;
	
	my $skip;
	$skip = 'skip' if ($org eq $current_org);
	$skip = 'pass' if ($org ne $current_org);
	
	return ($skip);
}

sub print_scaffold {
	my ($file, $defline, $sequence) = @_;
	
	#print sequence
	print{$file} ">" . $defline . "\n";
	my $len = length $sequence;
	for (my $i = 0; $i <= $len; $i += 60) {
		my $chunk = substr($sequence, $i, 60);
		print {$file} $chunk . "\n";
	}

	return;
}

sub median_of
{
    my $stat = Statistics::Descriptive::Full->new();
    $stat->add_data(@_);
    my $median = $stat->median;
    return $median;    
}

sub IQR_of {
	my $stat = Statistics::Descriptive::Full->new();
	$stat->add_data(@_);
	my $q1 = $stat->quantile(1);
	my $q3 = $stat->quantile(3);
	my $iqr = $q3 - $q1;
	my $min = List::AllUtils::max( $q1 - $ARGV{'--deviation'} * $iqr, 0 );
	my $max = $q3 + $ARGV{'--deviation'} * $iqr;
	return ($min, $max);
}


__END__

=head1 NAME

parse blast report and compute statistics on taxonomic affiliation

=head1 USAGE

    blastx-parsing <infiles> [optional arguments]

=head1 REQUIRED ARGUMENTS

=over

=item <infiles>

Path to input blast file [repeatable argument].

=for Euclid:
    infiles.type: readable
    repeatable
    
=head1 OPTIONS

=over

=item --taxdir=<string>

path to the taxonomy directory [default: string.default].

=for Euclid:
    string.type: string
    string.default: '/media/vol2/scratch/lcornet/synteny/taxdump/'
    
=item --contam-list'=<string>

List of contaminant Taxa to compute stat [default: string.default].

=for Euclid:
    string.type: string
    string.default: 'contam-taxa.list'
    
=item --blast-extension=<string>

Specifia the extension of blast report file, the fasta file and the
blast report must be the same out of extension [default: string.default].

=for Euclid:
    string.type: string
    string.default: '-sreads.bdblastx'    
    
=item --fasta-extension=<string>

Specifia the extension of blast report file, the fasta file and the
blast report must be the same out of extension [default: string.default].

=for Euclid:
    string.type: string
    string.default: '-sreads.fasta'    
    
=item --length=<string>

minmal length of alignment to be considered for define bistcore [default: string.default].

=for Euclid:
    string.type: string
    string.default: '30'   

=item --identity=<string>

minimal percentage of identity of alignment to be considered for define bistcore [default: string.default].

=for Euclid:
    string.type: string
    string.default: '70'
    
=item --bitscore=<string>

minimal percentage of bitscore for a hit to be considered for LCA [default: string.default].

=for Euclid:
    string.type: string
    string.default: '0.95'

=item --min-hit=<string>

minimal number of hit for a read to compute LCA [default: string.default].

=for Euclid:
    string.type: string
    string.default: '2'
    
=item --query-org=<string>

Name of Taxa of interest, supposed to be [default: string.default].

=for Euclid:
    string.type: string
    string.default: 'Cyanobacteria'
