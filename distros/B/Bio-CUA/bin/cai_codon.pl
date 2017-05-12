#!/usr/bin/env perl

use strict;
use warnings;
use lib '../lib';
use Bio::CUA::CUB::Builder;
use Bio::CUA::CodonTable;
use Getopt::Long;
use Fcntl qw/:seek/;
use File::Sort qw/sort_file/;
use File::Temp qw/ tempfile tempdir /;
our $VERSION = 0.02;

my $seqIO_pkg;

BEGIN{
	eval { require Bio::SeqIO; };

	if($@) # bioperl is not installed
	{
		require Bio::CUA::SeqIO;
		$seqIO_pkg = 'Bio::CUA::SeqIO';
	}else
	{
		$seqIO_pkg = 'Bio::SeqIO';
	}
}

my $sep = "\t"; # field separator
my $seqFile;
my $expFile;
my $gcId;
my $outFile;
my $select;
my $background;
my $normMethod;
my $minTotal; # the minimal count of an amino acid for being
# considered to calculate CAI parameters
my $help;

GetOptions(
	'i|seq-file=s'  => \$seqFile,
	'e|exp-file:s'  => \$expFile,
	's|select:s'  => \$select,
	'b|background:s'  => \$background,
	'o|out-file:s'  => \$outFile,
	'g|gc-id:i'  => \$gcId,
	'm|method:s' => \$normMethod,
	'h|help!'   => \$help
);

&usage() if($help or !defined($seqFile));

if($select)
{
	die "option '--exp-file' is needed as option '--select' is provided:$!" 
	unless($expFile);
}

$gcId ||= 1;
$outFile ||= '-';
$select ||= 'all';
$select = lc($select);
$normMethod ||= 'max';

warn "# Step 1: tabulate codons from sequences\n";
my $table = Bio::CUA::CodonTable->new(-id => $gcId) 
   or die "Creating codon table failed:$!";
my $builder = Bio::CUA::CUB::Builder->new(
	           -codon_table  => $table
		   )
   or die "Creating analyzer failed:$!";

# check the format of input sequences
my $isInputCodons = &_detect_format($seqFile);
my $codonListRef;
my ($sortedFh, $sortedExpFile);
if(!$isInputCodons and $expFile)
{
	# sort this $expFile first
	($sortedFh, $sortedExpFile) = tempfile();
	#warn "$sortedExpFile\n";
	sort_file({
		I => $expFile,
		o => $sortedExpFile,
		k => '2,2n',
		t => "\t" # field separator
	});
	my $idsRef;
	if($select eq 'all')
	{
		$idsRef = choose_ids($sortedFh, 'all');
	}elsif($select < 1) # a fraction
	{
		my $total = num_of_lines($expFile);
		$select = int($total * $select);
		# largest is at the end, -r option for sort does not work
		$idsRef = choose_ids($sortedFh, 'high', $select);
	}elsif($select > 1) # number of genes
	{
		$select = int($select);
		$idsRef = choose_ids($sortedFh, 'high', $select);
	}else
	{
		die "Unknown option '$select' for --select:$!";
	}
	
	$codonListRef = &read_codons($seqFile,$idsRef);
	# output_ids($idsRef,'positive');
}else # consider codons in all input sequences
{
	$codonListRef = &read_codons($seqFile, undef, $isInputCodons);
}

# now consider background data

my $backCodonListRef;
if($background)
{
	if(is_numeric($background))
	{
		die "option '--exp-file' is needed for selecting background data:$!" 
		unless($sortedFh);

		my $idsRef;
		if($background < 1) # a fraction
		{
			my $total = num_of_lines($expFile);
			$background = int($total * $background);
			# largest is at the end, -r option for sort does not work
			$idsRef = choose_ids($sortedFh, 'low', $background);
		}elsif($background > 1) # number of genes
		{
			$background = int($background);
			$idsRef = choose_ids($sortedFh, 'low', $background);
		}else
		{
			die "Unknown option '$background' for --background:$!";
		}
	
		$backCodonListRef = &read_codons($seqFile,$idsRef);

		#output_ids($idsRef,'negative');
	}elsif(-f $background) # a sequence file
	{
		my $isBackCodons = &_detect_format($background);
		$backCodonListRef = &read_codons($background, undef,
			$isBackCodons) or 
		die "reading codons from $background failed:$!";
	}else
	{
		die "Unknown data '$background' for option --background:$!";
	}
}

warn "# Step 2: calculate CAIs for codons\n";
if($background)	
{
	$builder->build_b_cai($codonListRef, $backCodonListRef,
		$minTotal, $outFile) or die "building codons' b_CAI failed:$!";
}else
{
	$builder->build_cai($codonListRef, $minTotal, $normMethod,
		$outFile) or 
	die "building codons' CAI failed:$!";
}

# remove temporary files
if($sortedExpFile)
{
	close $sortedFh;
	unlink $sortedExpFile;
}

warn "Work done!!\n";

exit 0;

sub output_ids
{
	my ($hash, $name) = @_;

	open(O,"> tmp_$name") or die $!;
	print O join("\n", keys %$hash), "\n";
	close O;
}

sub is_numeric
{
	my $num = shift;
	if($num =~ /^[+-]?[eE\d\.\-]+$/)
	{
		return 1;
	}else
	{
		return 0;
	}
}

# get the number of lines in a file
sub num_of_lines
{
	my ($file) = @_;
	my $totalNum;
	if(ref($file) eq 'GLOB')
	{
		$. = 0; # reset number to 0
		my $currPos = tell($file);
		seek($file, 0, SEEK_SET); # set to beginning
		1 while(<$file>);
		$totalNum = $.; # a special variable
		seek($file,$currPos,SEEK_SET); # set back the pointer
	}else
	{
		my $fh;
		open($fh, "< $file") or die "Can not open $file:$!";
		1 while(<$fh>);
		$totalNum = $.; # a special variable
		close $fh;
	}
	return $totalNum;
}

# read codons from given sequence IDs
sub read_codons
{
	my ($seqFile,$idsRef,$isCodons) = @_;
	# if $idsRef is not a hash reference, all the sequences in the
	# input file will be scanned.
	# $isCodons tells whether $seqFile stores codon counts or not
	
	my %codonList; # store all the codons of selected sequences
	if($isCodons) # read codons directly
	{
		my $fh;
		open($fh, "< $seqFile") or die "Can not open $seqFile:$!";
		while(<$fh>)
		{
			chomp;
			next if /^#/ or /^\s*$/;
			my ($codon, $cnt) = split $sep;
			$codon = uc($codon);
			$codon =~ tr/U/T/;
			$codonList{uc($codon)} += $cnt; # sum up the same codons
		}
		close $fh;

		return \%codonList;
	}

	unless(defined($idsRef) and ref($idsRef) eq 'HASH') # no selected IDs
	{
		return $builder->get_codon_list($seqFile);
	}

	my $io = $seqIO_pkg->new(-file => $seqFile, -format => 'fasta');
	my $seqCnt = 0;

	while(my $seq = $io->next_seq)
	{
		next unless($idsRef->{$seq->id});
		my $localCodons = $builder->get_codon_list($seq) or 
		(warn "Counting codons in ".$seq->id." failed\n" and next);
		while(my ($codon, $cnt) = each %$localCodons)
		{
			$codonList{$codon} += $cnt;
		}
		$seqCnt++;
	}

	return \%codonList;
}

# choose IDs from an input file
sub choose_ids
{
	my ($fh, $method, $cnt) = @_;
	$method = lc($method);
	# set the filehandle to the beginning
	seek($fh,0,SEEK_SET);
	my %data;
	my $counter = 0;
	if($method eq 'all')
	{
		while(<$fh>)
		{
			chomp;
			my @fields = split $sep;
			$data{$fields[0]}++;
		}
		# return _read_column($fh, 1);
	}elsif($method eq 'low')
	{
		while(<$fh>)
		{
			chomp;
			my @fields = split $sep;
			$data{$fields[0]}++;
			last unless(++$counter < $cnt);
		}
	}elsif($method eq 'high')
	{
		my $toSkip = num_of_lines($fh) - $cnt;
		while(<$fh>)
		{
			next unless(++$counter > $toSkip);
			chomp;
			my @fields = split $sep;
			$data{$fields[0]}++;
		}
	}else
	{
		die "Unknown method $method for choosing IDs in 'choose_ids':$!";
	}

	return \%data;
}

sub _read_column
{
	# the $fh may not be at the beginning
	my ($fh, $colNum, $cnt) = @_;
	my %data;
	while(<$fh>) 
	{
		last if(defined($cnt) and $cnt == 0);
		chomp;
		my @fields = split $sep;
		$data{$fields[$colNum - 1]}++; 
	}

	return \%data;
}

sub _detect_format
{
	my $file = shift;

	my $isCodons = 0;
	my $fh;
	open($fh, "< $file") or die "Can not open $file:$!";
	while(<$fh>)
	{
		next if /^#/; # comment line
		next if /^\s*$/;
		$isCodons = 1 unless(/^>/); # not fasta format
		last; # only first line is checked
	}
	close $fh;

	warn "# $file is in codon-count format\n";
	return $isCodons;
}

sub usage
{
	print <<USAGE;
Usage: $0 [options]

This program reads into fasta-formatted sequences or codon counts
and ouput CAI values for each codon. 

Mandatory options:

-i/--seq-file: a file containing protein-coding sequences in fasta
format or a list of codon counts. The latter lists the counts of
codons in the format 'codon1<tab>#1' with each codon per line and
<tab> as the field delimiter. The program distinguishes these two
formats based on the first non-empty/non-comment line: if it starts
with '>', then the format is regarded as 'fasta', otherwise codon
counts are expected.

Auxiliary options:

-e/--exp-file: a file containing sequence IDs and their expression

-s/--select:  how many sequences are chosen for CAI calculation.
all  = all IDs in the expression file given by --exp-file
0.## = the top fraction of highly expressed genes, say 0.30, then top
30% highly expressed genes.
###  = an integer such as 200, then the top 200 highly expressed
genes.
Default is 'all'.
This option is ignored if the input by --seq-file is codon counts.

-b/--background: data for background codon usage estimation.
0.## = a fraction (e.g.,0.30) of most lowly expressed genes in the
expression file by --exp-file
###  = a number (say 200) of most lowly expressed genes in the
expression file.
filename = a file containing protein-coding sequences or a list of
codon counts which will be anlyzed for background codon usage. See the
option --seq-file for format details.
When this option is given, bCAI is calculated.

-g/--gc-id:  ID of genetic code table. Default is 1, i.e., the
standard genetic code table. 

-m/--method: method to calculate CAI. Available values are 'max'
(default) and 'mean'. The former calculates the standard CAI while the
latter calcualtes mCAI.

-o/--out-file: the file to store the result. Default is standard output.

-h/--help: show this help message. For more detailed information, run
'perldoc cai_codon.pl'

Author:  Zhenguo Zhang
Contact: zhangz.sci\@gmail.com
Created:
Wed Mar  4 16:42:24 EST 2015

USAGE
	
	exit 1;
}

=pod

=head1 NAME

cai_codon.pl - a program to calculate CAI for each codon

=head1 VERSION

VERSION = 0.02

=head1 SYNOPSIS

This is a program to compute CAI at codon level with different
methods. It is part of distribution
L<http://search.cpan.org/dist/Bio-CUA/>

# calculate codon CAI by choosing the top 200 highly expressed genes
cai_codon.pl -i seqs.fasta -e gene_expression.tsv -s 200 -o CAI_top200

# the same as above but normalize RSCUs with expected RSCUs under even
# codon usage
cai_codon.pl -i seqs.fasta -e gene_expression.tsv -s 200 -o CAI_top200.by_mean -m mean

# normalize RSCUs by RSCUs derived from bottom 1000 lowely expressed genes
cai_codon.pl -i seqs.fasta -e gene_expression.tsv -s 200 -o CAI_top200.b1000 -b 1000

=head1 OPTIONS

All options have a short and a long forms, e.g., -i and --seq-file for
first option.

In the following text, RSCU stands for relative synonymous codon
usage.

=head3 Mandatory options

=over

=item -i/--seq-file

a file containing protein-coding sequences in fasta
format or a list of codon counts. The latter lists the counts of
codons in the format 'codon1<tab>#1' with each codon per line and
<tab> as the field delimiter. The program distinguishes these two
formats based on the first non-empty/non-comment line: if it starts
with '>', then the format is regarded as 'fasta', otherwise codon
counts are expected.

=back

=head3 Auxiliary options

=over

=item -e/--exp-file

a file containing sequence IDs and their expression in the forllowing
format:

	seq-id1E<lt>tabE<gt>0.67
	seq-id2E<lt>tabE<gt>2.57
	... ...

each line contains one sequence ID and the sequence's gene expression
level (RNA, protein, or else), separated by tab. The sequence IDs
must match the IDs in the sequence file specified above.

From this file, highly expressed genes will be selected according to
the gene expression rank. See below options.

If this option is omitted, all the sequences in the above sequence
file would be used for calculating CAIs.

=item -s/--select

determine how many sequences are chosen from the above expression
file (by option --exp-file). Available formats are: 

I<all>, all IDs in the expression file are chosen.

I<0.##>, a fraction of top highly expressed genes, say 0.30, then top
30% highly expressed genes are chosen.

I<###>, an integer, say 200, then the top 200 highly expressed genes
are chosen.

Default is I<all>. If the option --exp-file is omitted, this option
has no effect.

=item -b/--background

specify background data (e.g., lowly expressed
genes) from which the background codon usage is derived. Then each
codon's RSCU from highly expressed genes is divided by the codon's
RSCU from the background data; these normalized RSCUs are used for CAI
calculation. This method is termed 'background-normalization'.

How to specify background data: I<0.##>, I<###>, or I<filename>, the
former two formats choose a fraction
of or a number of genes from the most lowly expressed genes specified
in the expression file by --exp-file. See option --select for details
of the two specification formats. The last format specifies a
fasta-formatted sequence file containing protein-coding sequences or a list of
codon counts which will be anlyzed for background codon usage. See the
option --seq-file for format details.
When this option is given, bCAI is calculated.

=item -g/--gc-id

ID of genetic code table. See L<NCBI genetic code|
http://www.ncbi.nlm.nih.gov/Taxonomy/taxonomyhome.html/index.cgi?chapter=cgencodes>
for valid IDs. Default is 1, i.e., standard genetic code.

=item -m/--method

method to calculated CAI: I<max> or I<mean>.
The former is used by <Sharp and Li, 1987, NAR>, in which each codon's
RSCU is divided by the maximum of all synonymous codons to derive CAI.
The 'mean' method divides each codon's RSCU by the expected RSCU under
even codon usage to get CAI. For example, for an amino acid with four synonymous 
codons, the expected RSCU is 0.25 for each codon, so all observed
RSCUs of this amino acid's codons are divided by 0.25. These two
choices produce CAI and mCAI, respectively.

If option C<--background> is activated, the 'background-normalization'
method always uses the I<max> method to get final CAIs. 

=item -o/--out-file

file to store the result. Default is standard output, usually screen.

=back

=head1 AUTHOR

Zhenguo Zhang, C<< <zhangz.sci at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-bio-cua at
rt.cpan.org> or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Bio-CUA>.  I will be
notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=cut

=head1 SUPPORT

You can find documentation for this class with the perldoc command.

	perldoc Bio::CUA

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Bio-CUA>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Bio-CUA>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Bio-CUA>

=item * Search CPAN

L<http://search.cpan.org/dist/Bio-CUA/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2015 Zhenguo Zhang.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see L<http://www.gnu.org/licenses/>.

=cut

