#!/usr/bin/env perl

use strict;
use warnings;
use lib '../lib';
use Bio::CUA::CUB::Builder;
use Bio::CUA::CodonTable;
use Getopt::Long;

my $tRNAFile;
my $gcId;
my $outFile;
my $help;

GetOptions(
	't|tRNA=s'	=> \$tRNAFile,
	'g|gc-id:i'	=> \$gcId,
	'o|out-file:s'	=> \$outFile,
	'h|help!'	=> \$help
);

&usage() if($help or !defined($tRNAFile));

$gcId ||= 1;
$outFile ||= '-';

my $table = Bio::CUA::CodonTable->new(-id => $gcId);
my $builder = Bio::CUA::CUB::Builder->new(
	           -codon_table  => $table
		   );

$builder->build_tai($tRNAFile, $outFile) or 
die "building tAI failed:$!";

warn "Work done!!\n";

exit 0;

sub usage
{
	print <<USAGE;

Usage: $0 [options]

This program reads tRNA abundance (ussally gene copy number) in a
genome and calculate tAI (tRNA adaptation index) for each codon.

Options:

Mandatory options:

-t/--tRNA: the file containing tRNA abundance in the format:
	anti-codon1<tab>3
	anti-codon1<tab>6
	...   ...
each line contains one anticodon followed by the total copy number of
tRNAs harboring this anticodon.

Auxiliary options:

-g/--gc-id: ID of genetic code table. Used for mapping between codons
and amino acids.

-o/--out-file: the file to store the result. Default is standard
output.

-h/--help: show this help message. For more detailed information, run
'perldoc tai_codon.pl'

Author:  Zhenguo Zhang
Contact: zhangz.sci\@gmail.com
Created:
Sat May  2 00:45:05 EDT 2015

USAGE
	
	exit 1;
}

=pod

=head1 NAME

tai_codon.pl - a program to calculate tAI of each codon

=head1 VERSION

VERSION: 0.01

=head1 SYNOPSIS

This program calculates tAI (tRNA adaptaion index) at codon level,
which is part of distribution L<http://search.cpan.org/dist/Bio-CUA/>

# calculate tAI for drosophila melanogaster
tai_codon.pl -t dmel_tRNA_copy_number.tsv -o dmel_tAI.tsv

# one can get tRNA copy numbers from the database
# L<GtRNADB|http://gtrnadb.ucsc.edu/>

=head1 OPTIONS


=head3 Mandatory options:

=over

=item -t/--tRNA

the file containing tRNA abundance in the format:

	anti-codon1<tab>3
	anti-codon1<tab>6
	...   ...

each line contains one anticodon followed by the total copy number of
tRNAs harboring this anticodon.

=back

=head3 Auxiliary options:

=over

=item -g/--gc-id

ID of genetic code table. Used for mapping between codons
and amino acids.

=item -o/--out-file

the file to store the result. Default is standard output.

=item -h/--help

show this help message. For more detailed information, run
'perldoc tai_codon.pl'

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

