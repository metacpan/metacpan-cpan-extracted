#!/usr/bin/env perl

use strict;
use warnings;
use lib '../lib';
use Bio::CUA::CUB::Calculator;
use Bio::CUA::CodonTable;
use Getopt::Long;

our $VERSION = 0.12;
my @args = @ARGV;
my $sep = "\t";
my $seqIO_pkg;

BEGIN{
	eval { require Bio::SeqIO; };
	
	if($@)
	{
		require Bio::CUA::SeqIO;
		$seqIO_pkg = 'Bio::CUA::SeqIO';
	}else
	{
		$seqIO_pkg = 'Bio::SeqIO';
	}
}

my $seqFile;
my $gcId;
my $outFile;
my $taiFile;
my $caiFile;
my $fopFile;
my $encMethods;
my $baseCompFile;
my $help;
my $lite;

GetOptions(
	's|seq-file=s'  => \$seqFile,
	'g|gc-id:i'     => \$gcId,
	't|tai-param:s' => \$taiFile,
	'f|fop-param:s' => \$fopFile,
	'c|cai-param:s' => \$caiFile,
	'e|enc-methods:s' => \$encMethods,
	'l|lite!'       => \$lite,
	'o|out-file:s' => \$outFile,
	'b|base-comp:s'	=> \$baseCompFile,
	'h|help!'     => \$help
);

&usage() if($help or !defined($seqFile));

$gcId ||= 1;
$outFile ||= '-';
#$encMethods ||= 'enc';

my @encs = split ',', $encMethods if($encMethods);

# set up parameters for calculating CUB metrics
my %params; # to CUB analyzer
my %baseCompositions;
if(grep /^encp/,@encs) # there are methods needing background data
{
	die "option --base-comp is missing for encp and its related methods:$!" 
	unless($baseCompFile);
	if(-f $baseCompFile) # this is a file
	{
		open(B,"< $baseCompFile") or die "Can not open $baseCompFile:$!";
		while(<B>)
		{
			next if /^#/;
			chomp;
			my @fields = split "\t";
			# we may implement checking the validity of the data here in
			# future
			$baseCompositions{$fields[0]} = [@fields[1..4]];
		}
		close B;
	}else # just a comma-separated 4 values
	{
		my @baseFreq = split ',', $baseCompFile;
		die "The length of specified base frequency '$baseCompFile'".
		" is not 4:$!" unless($#baseFreq == 3);
		$params{'-base_background'} = \@baseFreq;
	}
}

warn "Step 1: build analyzer\n";

my $table = Bio::CUA::CodonTable->new(-id => $gcId) or die $!;
$params{'-codon_table'}= $table;
$params{'-tai_values'} = $taiFile if($taiFile);
$params{'-cai_values'} = $caiFile if($caiFile);
$params{'-optimal_codons'} = $fopFile if($fopFile);

my $cub  = Bio::CUA::CUB::Calculator->new(%params) or die $!;

warn "Step 2: calculating parameters\n";
my $io = $seqIO_pkg->new(-file => $seqFile, -format => 'fasta') or die
"Can't create sequence IO on $seqFile:$!";

open(O, "> $outFile") or die "Can not open $outFile:$!";
my @header = qw/seq_id/;
push @header, qw/length AAs GC GC3/ unless($lite);
push @header, @encs if(@encs);
push @header, 'tai' if($taiFile);
push @header, 'cai' if($caiFile);
push @header, 'fop' if($fopFile);

my @allAAtypes = sort($table->all_amino_acids); # make the amino acids
# always in alphabet order
print O "# produced by $0 @args\n";
print O "# amino acid order for AAs: ",join(',',@allAAtypes),"\n"
unless($lite);
print O '#', join($sep, @header),"\n";
my $counter = 0;
while(my $seq = $io->next_seq)
{
	my $codonList = $cub->get_codon_list($seq) or 
	(warn "Get codons for ".$seq->id." failed\n" and next);

	my @result = ($seq->id);
	unless($lite)
	{
		# count amino acids
		my %AAs;
		my $totalPepLen = 0;
		while(my ($codon, $cnt) = each %$codonList)
		{
			next if($table->is_stop_codon($codon));
			my $AA = $table->translate($codon) or 
			die "Can not translate $codon:$!";
			$AAs{$AA} += $cnt;
			$totalPepLen += $cnt;
		}
		my $aaCounts = join(',', map { $AAs{$_} || 0 } @allAAtypes);

		# now GC content
		my $gcFrac = $cub->gc_frac($codonList);
		my $gc3Frac = $cub->gc_frac($codonList,3);

		# store results
		push @result, $totalPepLen, $aaCounts;
		push @result, map {  _format_num($_) } ($gcFrac, $gc3Frac);
	}

	# get base composition for this sequence if available
	my $baseComp = $baseCompositions{$seq->id}
	if(%baseCompositions);
	# call (codons, minTotal, base composition)
	# set undef value to NA
	my @encResult = @encs? 
	map { $cub->$_($codonList,undef,$baseComp) || 'NA' } @encs : ();
	# set ENC which is > 62 to 62
	push @result, map { ($_ ne 'NA' and $_ > 62)? 62 : _format_num($_) } @encResult;

	my $tai = $cub->tai($codonList) or die $! if($taiFile);
	my $cai = $cub->cai($codonList) or die $! if($caiFile);
	my $fop = $cub->fop($codonList) or die $! if($fopFile);
	push @result, _format_num($tai) if(defined $tai);
	push @result, _format_num($cai) if(defined $cai);
	push @result, _format_num($fop) if(defined $fop);

	print O join($sep, @result),"\n";

	warn "# $counter sequences have been analyzed\n" 
	if(++$counter %	500 == 0);
}

close O;

warn "Work [$counter sequences] is done!!\n";

exit 0;

sub _format_num
{
	my ($num) = @_;
	return $num if($num eq 'NA');
	my $field = 7;
	return sprintf("%.*f",, $field, $num);
}

sub usage
{
	print <<USAGE;
Usage: $0 [options]

This program computes CUB metrics and additional sequence statistics
for each sequence. Available CUB metrics are ENC, CAI, tAI, Fop.

Options:

-s/--seq-file: file containing sequences in fasta format, from which
CUB metrics are computed.

-g/--gc-id:  genetic code table ID used for deriving amino acids for
sequences in input file. Default is 1, i.e., standard table

-t/--tai-param:  the file containing tAI values for each codon in the
format 'codon<tab>tAI_value'. If not provided, tAI values would not be
computed.

-c/--cai-param: similar to --tai-param, except for CAI values.

-f/--fop-param: a file containing pre-defined optimal codons, one
codon per line.

-e/--enc-methods: methods for ENC calculation. Available values are 
enc, enc_r, encp, and encp_r.

-b/--base-comp: a file or four numbers separated by comma. When
provided is a file, it is assumed that sequence-specific background 
base compositions are given in the format like:
	seq_id1	#A	#T	#C	#G
	seq_id2	#A	#T	#C	#G
	...   ...
When provided are numbers, it should be like
	0.2,0.3,0.3,0.2
giving the frequency of A/T/C/G in order.
This option is needed when computing encp* versions of ENC.

-l/--lite: in default, the program outputs counts of amino acids, GC
content, and protein lengths. If this switch option is given, these
parameters will not be output.

-o/--out:  the file to store the results. Default is to standard output.

-h/--help: show this message. For more details, run 
'perldoc cub_seq.pl'

Author:  Zhenguo Zhang
Contact: zhangz.sci\@gmail.com
Created:
Sat May  2 22:22:07 EDT 2015


USAGE
	
	exit 1;
}

=pod

=head1 NAME

cub_seq.pl - a program to calculate sequence codon usage bias
metrics and other sequence parameters.

=head1 VERSION

VERSION: 0.12

=head1 SYNOPSIS

This program computes CUB metrics for each sequence; the types of
computed CUB metrics depend on the provided options (see below).

In addition to CUB metrics, the program also computes some other
features such as counts of amino acids, GC-content of the whole
sequence and the 3rd codon positions.

  # compute ENC, ENC_r, CAI, and tAI for each sequence in file cds.fa
  cub_seq.pl --cai CAI_codon.top_200 --tai tAI_codon \
  --enc enc,enc_r --seq cds.fa -o CUB_seq.tsv

  # the same as above but not output GC content, AA counts and protein
  # lengths
  cub_seq.pl --cai CAI_codon.top_200 --tai tAI_codon \
  --enc enc,enc_r --seq cds.fa -o CUB_seq.tsv --lite

=head1 OPTIONS

=head3 Mandatory options

=over

=item -s/--seq-file

file containing sequences in fasta format, from which each sequence's
CUB metrics are computed.

=back

=head3 Auxiliary options

=over

=item -g/--gc-id

ID of genetic code table used for identifying amino acid encoded by
each codon. Default is 1, i.e., standard code. See L<NCBI Genetic
Code|http://www.ncbi.nlm.nih.gov/Taxonomy/Utils/wprintgc.cgi?mode=t>
for valid IDs.

=item -t/--tai-param

file containing tAI value for each codon in the
format 'codon<tab>tAI_value', which can be produced by
L<tai_codon.pl>. If not given, tAI values would not be
computed.

=item -c/--cai-param

similar to --tai-param, except that CAI values are
provided in the same format. This file may be produced by
L<cai_codon.pl>. If not given, CAI values would not be computed.

=item -f/--fop-param

a file containing pre-defined optimal codons, one codon per line.
Optimal codons can be selected using different ways, such as selecting 
high-tAI codons or those preferred in highly expressed genes.

=item -e/--enc-methods

methods for ENC calculations. Available values are I<enc>, I<enc_r>,
I<encp>, and I<encp_r>. I<encp*> versions corrects background
GC-content in calculations. I<*_r> versions uses a new method to
estimate missing F values. Check module L<Bio::CUA::CUB::Calculator>
to see details of these methods. Default is I<enc>. Multiple methods
can be specified as comma-separated string such as 'enc,encp,enc_r'.

=item -b/--base-comp

This option is needed when computing encp* versions of ENC. The base
compositions are used as background base compositions to calculate
expected codon frequency in the sequences. It may be helpful for one
to exclude the effect of mutational bias on codon usage.
This option has no effect unless I<encp*> version
methods are specified in I<--enc-methods>.

Acceptable values are either a file or four numbers separated by comma. 
When provided is a file, it is assumed that sequence-specific background 
base compositions are given in the format like:

	seq_id1	#A	#T	#C	#G
	seq_id2	#A	#T	#C	#G
	...   ...

where #A/#T/#C/#G are counts or fractions of each base type in background data
(e.g., introns) for each sequence. For sequences without background
base composition information, 'NA' will be returned from I<encp*>
methods.

When provided are numbers, it should be like
	
	0.2,0.3,0.3,0.2

giving the frequency of A/T/C/G in order.

=item -l/--lite

A switch option. In default, the program outputs counts of amino acids, GC
content, and protein lengths. If this option is set these parameters will 
not be output.

=item -o/--out-file

the file to store the results. Default is to standard output, usually
screen.

=item -h/--help

show the brief help message. 

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

=head1 UPDATES

0.12 - Thu Jun  4 11:31:03 EDT 2015
       
	   1. update documentation

0.11 - Thu May 21 16:00:28 EDT 2015
       
	   1. modify/add option --base-comp and --lite.

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

