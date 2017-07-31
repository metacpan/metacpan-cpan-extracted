#!/usr/bin/perl

use strict;
use utf8;
use open qw(:utf8 :std);

use Getopt::Long;
use Pod::Usage;

use File::Basename;
use Brat::Handler;

binmode(STDIN, ':utf8');
binmode(STDOUT, ':utf8');
binmode(STDERR, ':utf8');

my $verbose;
my $help;
my $man;
my $inputDir;
my @inputDirs;
my $inputFile;
my @inputFiles;
my $outputFile = "-";
my $fileList;
my $bratElt;

if (scalar(@ARGV) ==0) {
    $help = 1;
}

Getopt::Long::Configure ("bundling");

GetOptions('help|?'     => \$help,
	   'man'     => \$man,
	   'verbose|v'     => \$verbose,
	   'input-dir|d=s' => \@inputDirs,
	   'input-file|i=s' => \@inputFiles,
	   # 'output-file|o=s' => \$outputFile,
	   'file-list|l=s' => \$fileList,
    );

pod2usage(1) if $help;
pod2usage(-exitstatus => 0, -verbose => 2) if $man;

my $brat = Brat::Handler->new();

foreach $inputFile (@inputFiles) {
    $brat->_bratAnnotations($brat->loadFile($inputFile));
} 

foreach $inputDir (@inputDirs) {
#    $brat->_inputDir($inputDir);
    $brat->loadDir($inputDir);
}

if (defined $fileList) {
    $brat->loadList($fileList);
}

# my $concatAnn = $brat->concat();

if (!defined $outputFile) {
    $outputFile = "-";
}

# $brat->printTermList($outputFile);

my $nbFiles = 0;
my $nbTerms = 0;
my $nbRels = 0;
my $sumTextSize = 0;
my $minTerms = 0;
my $maxTerms = 0;
my $minRels = 0;
my $maxRels = 0;


# $concatAnn->printTermList($outputFile, "1");
foreach $bratElt (@{$brat->_bratAnnotations}) {
    print "\n";
    $nbFiles++;
    print "Filename ($nbFiles): " . basename(join(":", @{$bratElt->_textFilename})) . "\n";
    $bratElt->printStats('-',0);
}

print "\n";
print $brat->getStats . "\n";

########################################################################

=head1 NAME

bratStatistics.pl - Perl script for printing the statistics of the brat file


=head1 SYNOPSIS

bratStatistics.pl [options]

where option can be --help --man --verbose

=head1 OPTIONS AND ARGUMENTS

=over 4

=item --input-dir <filename>, -d <filename>

Specification of the name of the directory containing the input files.
Several directories can be specified.

=item --input-file <filename>, -i <filename>

Specification of the name of an input file (either the text or
annotation file). Several input files can be specified.

=item --file-list <filename>, -l <filename>

<Specification of the list of files for which the statistics are needed. Each line contains
one file name.

=item --help

print help message for using bratStatistics.pl

=item --man

print man page of bratStatistics.pl

=item --verbose

Go into the verbose mode

=back

=head1 DESCRIPTION

This script computes the statistics of the brat annotation files
(<http://brat.nlplab.org/>). For each file, statistics are: the number
of words, the number of terms, the number of relations, the number of
terms and relations per type The minimal and the maximal of each
statistics, except the types, are also provided.

If no output files are specified, the statistics are printed on the
standard output.


=head1 EXAMPLES

Print and compute the statistics for all the files in the directory C<examples>.

   bratStatistics.pl -d examples

Print and compute the statistics of all the three files.

   bratStatistics.pl -i examples/taln-2012-long-001-resume.txt -i examples/taln-2012-long-002-resume.ann -i examples/taln-2012-long-003-resume.txt


Print and compute all the files indicated in C<examples/list.txt>.

   bratStatistics.pl -l examples/list.txt


=head1 SEE ALSO

http://brat.nlplab.org/

=head1 AUTHOR

Thierry Hamon, E<lt>hamon@limsi.frE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 Thierry Hamon

This is free software; you can redistribute it and/or modify it under
the same terms as Perl itself, either Perl version 5.8.4 or, at your
option, any later version of Perl 5 you may have available.

=cut

