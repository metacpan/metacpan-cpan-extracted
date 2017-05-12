#!/usr/bin/perl

use strict;
use utf8;
use open qw(:utf8 :std);

use Getopt::Long;
use Pod::Usage;

use Brat::Handler;

binmode(STDIN, ':utf8');
binmode(STDOUT, ':utf8');
binmode(STDERR, ':utf8');

my $verbose;
my $help;
my $man;
my $inputDir;
my @inputFiles;
my $inputFile;
my $outputFile = "-";
my $fileList;

if (scalar(@ARGV) ==0) {
    $help = 1;
}

Getopt::Long::Configure ("bundling");

GetOptions('help|?'     => \$help,
	   'man'     => \$man,
	   'verbose|v'     => \$verbose,
	   'input-dir|d=s' => \$inputDir,
	   'input-file|i=s' => \@inputFiles,
	   'output-file|o=s' => \$outputFile,
	   'file-list|l=s' => \$fileList,
    );

pod2usage(1) if $help;
pod2usage(-exitstatus => 0, -verbose => 2) if $man;

my $brat = Brat::Handler->new();

foreach $inputFile (@inputFiles) {
    $brat->_bratAnnotations($brat->loadFile($inputFile));
} 

if (defined $inputDir) {
#    $brat->_inputDir($inputDir);
    $brat->loadDir($inputDir);
}

if (defined $fileList) {
    $brat->loadList($fileList);
}

my $concatAnn = $brat->concat();

$concatAnn->print($outputFile);

########################################################################

=head1 NAME

concatBratFiles.pl - Perl script for concatenating Brat files


=head1 SYNOPSIS

concatBratFiles.pl [options]

where option can be --help --man --verbose

=head1 OPTIONS AND ARGUMENTS

=over 4

=item --input-dir <filename>, -d <filename>

Specification of the name of the directory containing the input files.

=item --input-file <filename>, -i <filename>

Specification of the name of an input file (either the text or
annotation file). Several input files can be specified.

=item --output-file <filename>, -o <filename>

Specification of the name of the output files (either the text or
annotation file). The filename can be C<-> to print the results on the
standard output.

=item --file-list <filename>, -l <filename>

Specification of the list of files to concatenate. Each line contains
one file name.

=item --help

print help message for using concatBratFiles.pl

=item --man

print man page of concatBratFiles.pl

=item --verbose

Go into the verbose mode

=back

=head1 DESCRIPTION

This script concatenates several files which have been annotated with
Brat (<http://brat.nlplab.org/>). Two output files are created: a text
file which contains all the input text files, and a annotation file
which contains all the annotations of the input files. Annotations are
merged and their offset are shift.

It is required the name of the output file has the C<txt> or C<ann>
extension.

If no output files are specified, the concatenated files (text and
annotations) are printed on the standard output.


=head1 EXAMPLES

Concatenation of all the files in the directory C<examples> and print
text in the file C<concat1.txt> and the annotations in the file
C<concat1.ann>.

   concatBratFiles.pl -d examples -o concat1.ann


Concatenation of all the three files and print
text in the file C<concatFile.txt> and the annotations in the file
C<concatFile.ann>.

   concatBratFiles.pl -i examples/taln-2012-long-001-resume.txt -i examples/taln-2012-long-002-resume.ann -i examples/taln-2012-long-003-resume.txt -o concatFile.txt


Concatenation of all the files indicated in C<examples/list.txt> and
print text in the file C<concat2.txt> and the annotations in the file
C<concat2.ann>.

   concatBratFiles.pl -l examples/list.txt -o concat2.ann



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

