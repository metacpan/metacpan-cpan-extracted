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
	   'output-file|o=s' => \$outputFile,
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

#my $concatAnn = $brat->concat();


if (!defined $outputFile) {
    $outputFile = "-";
}

$brat->printTermList($outputFile);
#$concatAnn->printTermList($outputFile, "1");
# foreach $bratElt (@{$brat->_bratAnnotations}) {
#     $bratElt->printTermList($outputFile, "1");
# }


########################################################################

=head1 NAME

brat2termlist.pl - Perl script for printing the list of terms in the brat file


=head1 SYNOPSIS

brat2termlist.pl [options]

where option can be --help --man --verbose

=head1 OPTIONS AND ARGUMENTS

=over 4

=item --input-dir <filename>, -d <filename>

Specification of the name of the directory containing the input files.
Several directories can be specified.

=item --input-file <filename>, -i <filename>

Specification of the name of an input file (either the text or
annotation file). Several input files can be specified.

=item --output-file <filename>, -o <filename>

Specification of the name of the output file. The filename can be C<->
to print the results on the standard output.

=item --file-list <filename>, -l <filename>

Specification of the list of files to concatenate. Each line contains
one file name.

=item --help

print help message for using brat2termlist.pl

=item --man

print man page of brat2termlist.pl

=item --verbose

Go into the verbose mode

=back

=head1 DESCRIPTION

This script prints the terms of several files which have been
annotated with Brat (<http://brat.nlplab.org/>). The output file can
be specified. Otherwise, terms are printed on the standard output.

=head1 EXAMPLES

Print the terms of all the files in the directory C<examples> in the
file C<termlist1.txt>.

   brat2termlist.pl -d examples -o termlist1.txt


Print the terms of all the three file in the file C<termlist2.txt>.

   brat2termlist.pl -i examples/taln-2012-long-001-resume.txt -i examples/taln-2012-long-002-resume.ann -i examples/taln-2012-long-003-resume.txt -o termlist2.txt


Print the terms of all the files indicated in C<examples/list.txt> in
the file C<termlist3.txt>.

   brat2termlist.pl -l examples/list.txt -o termlist3.txt

Print the terms of all the files indicated in C<examples/list.txt> on the standard output.

   brat2termlist.pl -l examples/list.txt

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

