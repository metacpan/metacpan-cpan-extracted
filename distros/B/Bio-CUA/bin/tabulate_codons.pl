#!/usr/bin/env perl

use strict;
use warnings;
use lib '../lib';
use Bio::CUA::Summarizer;
use Bio::CUA::SeqIO;
use Getopt::Long;

my $sep = "\t";
my @args = @ARGV;
my $seqFile;
my $idFile;
my $outFile;
my $help;
my $each;
my $gcId = 1;

GetOptions(
	's|seq-file=s'	=> \$seqFile,
	'i|id-file:s'	=> \$idFile,
	'o|out-file:s'	=> \$outFile,
	'h|help!'	=> \$help,
	"e|each!"   => \$each
);

&usage() if($help or !defined($seqFile));

$outFile ||= '-';

my $idsRef = _read_ids($idFile) if($idFile);

my $sum = Bio::CUA::Summarizer->new(-codon_table => $gcId);
# get codon order
my $table = $sum->codon_table;
my @codons = $table->all_codons or die $!;
# get AA order
my @AAs = map {$table->translate($_)} @codons;

my $outFh;
open($outFh, "> $outFile") or die "Cannot open $outFile for write:$!";
print $outFh "# Produced by $0 @args\n";

warn "# Counting codons from $seqFile ...\n";
if($each) # we have process each sequence separately
{
	# print outfile headers
	print $outFh "# each row contains the counts of codons for each".
	" sequence and the last comment line lists the amino acids coded".
	" by codons\n";
	print $outFh "#", join($sep,"seqId", @AAs),"\n";
	print $outFh join($sep,"seqId", @codons),"\n";
	my $counter = 0;
	# process each sequence separately
	my $io = Bio::CUA::SeqIO->new(-file => $seqFile, -format => 'fasta') or
	die "Cannot open '$seqFile' for codons:$!";
	while(my $seq = $io->next_seq)
	{
		my $id = $seq->id;
		next unless(!$idsRef or exists($idsRef->{$id}));
		my $localCodons = $sum->get_codon_list($seq) or
		(warn "Counting codons in $id failed\n" and next);
		&output_codon_row($id,$localCodons);
		warn "# $counter sequences have been processed\n"
		if(++$counter % 2000 == 0);
	}
}else
{
	# print outfile headers
	print $outFh "# each row is the codon, its count, and the coded amino acid\n";
	print $outFh join($sep, qw/codon count AA/),"\n";
	my $codonList;
	if($idsRef) # sequences have to be filtered
	{
		my $io = Bio::CUA::SeqIO->new(-file => $seqFile, -format =>
			'fasta') or die "Cannot open '$seqFile' for codons:$!";
		while(my $seq = $io->next_seq)
		{
			my $id = $seq->id;
			next unless(exists($idsRef->{$id}));
			my $localCodons = $sum->get_codon_list($seq) or
			(warn "Counting codons in $id failed\n" and next);
			while(my ($codon, $cnt) = each %$localCodons)
			{
				$codonList->{$codon} += $cnt;
			}
		}
	}else # no filtering
	{
		$codonList = $sum->get_codon_list($seqFile) or 
		die "Get codons from '$seqFile' failed:$!";
	}
	&output_codon_column($codonList);
}

close $outFh;
warn "Work done!!\n";

exit 0;

# write out codons by column
sub output_codon_column
{
	my $codonHash = shift;

	for(my $i = 0; $i <= $#codons; $i++)
	{
		my $codon = $codons[$i];
		print $outFh join($sep, $codon, $codonHash->{$codon},$AAs[$i]),"\n";
	}

	return 1;
}

sub output_codon_row
{
	my ($id, $codonHash) = @_;

	my @orderedCnts = map {$codonHash->{$_} || 0} @codons;

	print $outFh join($sep, $id, @orderedCnts), "\n";

	return 1;
}

sub _read_ids
{
	my $file = shift;

	my $fh;
	open($fh, "< $file") or die "Can not open $file:$!";
	my %ids;
	while(<$fh>)
	{
		next if /^#/ or /^\s*$/;
		chomp;
		my ($id) = split $sep;
		$ids{$id}++;
	}
	close $fh;

	return \%ids;
}

sub usage
{
	print <<USAGE;

Usage: $0 [options]

This program reads fasta-formated seqences and counts codons in them.

Options:

Mandatory options:

-s/--seq-file: the file containing fasta-formated sequences.

Auxiliary options:

-i/--id-file: a file containing sequence IDs (should match those in the
sequence file by '--seq-file'), one ID per line. If this file is
provided, only sequences matching the contained IDs will be analyzed.
Otherwise all the sequences in the input sequence file.

-e/--each: a switch option. If provided, codons are counted for each
sequence. Default is summing up all the codons in all the sequences.

-o/--out-file: the file to store the result. Default is standard
output, usually the screen.

-h/--help: show this help message. For more detailed information, run
'perldoc tabulate_codons.pl'

Author:  Zhenguo Zhang
Contact: zhangz.sci\@gmail.com
Created:
Sun Jul 12 13:09:56 EDT 2015

USAGE
	
	exit 1;
}

=pod

=head1 NAME

tabulate_codons.pl - a program to output codons in a sequence file as
a table

=head1 VERSION

VERSION: 0.01

=head1 SYNOPSIS

This progran reads fasta-formated sequences and output codon counts in
the sequence as a table.

 # count the codons of all sequences in longest_cds.dmel_5_57.fa
 tabulate_codons.pl -s longest_cds.dmel_5_57.fa -o codon_counts.tsv

 # the same as above, but output counts for each sequence
 tabulate_codons.pl -s longest_cds.dmel_5_57.fa -o codon_counts_each.tsv --each

 # you can also count for a subset of sequences, like
 tabulate_codons.pl -s longest_cds.dmel_5_57.fa -o \
 codon_counts_sub.tsv --id-file subset_ids.tsv

 # subset_ids.tsv contains sequence IDs, one ID per line

=head1 OPTIONS

=head3 Mandatory options:

=over

=item -s/--seq-file

the file containing fasta-formated sequences.

=back

=head3 Auxiliary options:

=over

=item -i/--id-file

a file containing sequence IDs. This option is used to filter the
sequences in the file by option L</-s>, so that only sequences listed
in this id-file are parsed. Note, the IDs should match those in the
sequence file by L</-s>, one ID per line. 
In default, all the sequences in the input file are analyzed.

=item -e/--each

a switch option. If provided, codons are counted for each
sequence. Default is summing up all the codons in all the sequences.

=item -o/--out-file

the file to store the result. Default is standard output.

=item -h/--help

show this help message. For more detailed information, run
'perldoc tabulate_codons.pl'

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

