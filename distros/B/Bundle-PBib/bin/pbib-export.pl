#! /usr/bin/perl
# $Id: pbib-export.pl 24 2005-07-19 11:56:01Z tandler $

=head1 NAME

pbib-export.pl - export references from the PBib database

=head1 SYNOPSIS

  perl pbib-export.pl -to I<outfile.bib>
  perl pbib-export.pl -to I<outfile.bib> I<filename1> ...

=head1 DESCRIPTION

Export all references in the Biblio DB
to a format supported by bp (e.g. bibtex).

If input files are given, these are scanned for references
and only references found are exported. You can use this, e.g., 
if you want to distribute the references used in a paper together 
with the paper in a machine-readable format.

Please check the bp documentation if you want to export the 
references in a format other than BibTeX ...

=cut

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib", '$FindBin::Bin/../lib/Biblio/bp/lib';

# for debug
use Data::Dumper;

# used modules
use Getopt::Long;

# used own modules
use Biblio::Biblio;
use Biblio::BP;
use PBib::Config;
use PBib::PBib;


# read config

my $config = new PBib::Config();


# get all known references

print STDERR "query biblio for known references\n";
my $bib = new Biblio::Biblio(%{$config->option('biblio')})
	or die "can't open biblio database!\n";

my $refs = $bib->queryPapers();
print "\n";


# select destination format etc.

Biblio::BP::format('auto:auto', 'bibtex:tex');
@ARGV = Biblio::BP::stdargs(@ARGV);

#
#
# the following has been taken from bp's conv.pl
# and adapted to Biblio package (ptandler, 02-03-28)
#
#

my (@files, $outfile);

while (@ARGV) {
  $_ = shift @ARGV;
  /^--$/      && do { push(@files, @ARGV);  last; };
  /^--?help$/   && do { &dieusage; };
  /^--?to/      && do { $outfile = shift @ARGV; next; };
  /^-/        && do { print STDERR "Unrecognized option: $_\n"; next; };
  push(@files, $_);
}

# Note that unlike some programs like rdup, we can be used as a pipe, so
# we can't die with a usage output if we have no arguments.

# output to STDOUT if nothing was specified.
$outfile = '-' unless defined $outfile;
# check that if the file exists, we can write to it.
if (-e $outfile && !-w $outfile) {
  die "Cannot write to $outfile\n";
}
# check that we won't be overwriting any files.
if ($outfile ne '-') {
  foreach my $file (@files) {
    next if $file eq '-';
    die "Will not overwrite input file $file\n" if $file eq $outfile;
  }
}

#
# filter if input files are given
#

if( @files ) {
	# scan files for references
	my $pbib = new PBib::PBib('refs' => $refs);
	$refs = $pbib->filterReferencesForFiles(@files);
}


# print out a little message on the screen
my ($informat, $outformat) = Biblio::BP::format();
print STDERR "Using bp, version ", Biblio::BP::doc('version'), ".\n";
print STDERR "Writing: $outformat\n";
print STDERR "\n";

# clear errors.  Not really necessary.
# Biblio::BP::errors('clear');


### CAUTION: This currently works only if the file is not yet open (I guess ...)
Biblio::BP::export($outfile, $refs);


sub dieusage {
  my($prog) = substr($0,rindex($0,'/')+1);

  my $str =<<"EOU";
Usage:

  perl pbib-export.pl -to <outfile.bib>
  perl pbib-export.pl -to <outfile.bib> <filename1> ...

If filenames are given, the export will be filtered to the references used in these files only.

Arguments:
  -to  Write the output to <outfile> instead of the standard out

  -bibhelp         general help with the bp package
  -supported       display all supported formats and character sets
  -hush            no warnings or error messages
  -debugging=#     set debugging on or off, or to a severity number
  -error_savelines warning/error messages also include the line number
  -informat=IF     set the input format to IF
  -outformat=OF    set the output format to OF
  -format=IF,OF    set the both the input and output formats
  -noconverter     always use the long conversion, never a special converter
  -csconv=BOOL     turn on or off character set conversion
  -csprot=BOOL     turn on or off character protection
  -inopts=ARG      pass ARG as an option to the input format
  -outopts=ARG     pass ARG as an option to the output format

Convert a Refer file to BibTeX:
	$prog  -format=refer,bibtex  in.refer  -to out.bibtex

Convert an Endnote file to an HTML document using the CACM style
	$prog  -format=endnote,output/cacm:html  in.endnote  -to out.html

EOU

  die $str;
}
