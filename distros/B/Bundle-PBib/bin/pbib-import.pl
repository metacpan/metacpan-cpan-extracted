#! /usr/bin/perl
# $Id: pbib-import.pl 18 2004-12-12 07:41:44Z tandler $

=head1 NAME

pbib-import.pl - import references into the PBib database

=head1 SYNOPSIS

  perl pbib-import.pl I<filename1> I<filename2> ...

=head1 DESCRIPTION

Import references in a format supported by bp (e.g. bibtex)
into the Biblio DB.

Use C<pbib-import.pl --help> to see available options.

=cut

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib", '$FindBin::Bin/../lib/Biblio/bp/lib';

# for debug
use Data::Dumper;

# used modules
# use Getopt::Long;

# used own modules
use Biblio::Biblio;
use Biblio::BP;
# use Biblio::Util;
use PBib::Config;

# process standard args
@ARGV = Biblio::BP::stdargs(@ARGV);

#
#
# the following has been taken from bp's conv.pl
# and adapted to Biblio package (ptandler, 02-03-28)
#
#

my @files;
my $default_category = undef;
my $create_citekey = undef;
my $dont_store = undef;

while (@ARGV) {
  $_ = shift @ARGV;
  /^--$/      && do { push(@files, @ARGV);  last; };
  /^--?help$/   && do { &dieusage; };
  /^--?cat(egory)?$/ && do { $default_category = shift @ARGV; next; };
  /^--?citekey$/ && do { $create_citekey = 1; next; };
  /^--?dontstore$/ && do { $dont_store = 1; next; };
  /^-/        && do { print STDERR "Unrecognized option: $_\n"; next; };
  push(@files, $_);
}

# Note that unlike some programs like rdup, we can be used as a pipe, so
# we can't die with a usage output if we have no arguments.

# input from STDIN if nothing was specified.
unshift(@files, '-') unless @files;
### output to STDOUT if nothing was specified.
###$outfile = '-' unless defined $outfile;
### check that if the file exists, we can write to it.
##if (-e $outfile && !-w $outfile) {
##  die "Cannot write to $outfile\n";
##}
### check that we won't be overwriting any files.
##if ($outfile ne '-') {
##  foreach my $file (@files) {
##    next if $file eq '-';
##    die "Will not overwrite input file $file\n" if $file eq $outfile;
##  }
##}

my $config = new PBib::Config();
my $refs = Biblio::BP::import(
	{
		'-category' => $default_category, 
		'-citekey' => $create_citekey,
	}, @files);
unless( $dont_store ) {
	my $bib = new Biblio::Biblio(%{$config->option('biblio')})
		or die "can't open biblio database!\n";
	print STDERR "storing ", scalar(@$refs), " references\n";
	foreach my $ref (@$refs) {
		$bib->storePaper($ref)
	}
	$bib->commit();
}

sub dieusage {
  my($prog) = substr($0,rindex($0,'/')+1);

  my $str =<<"EOU";
Usage: $prog [<bp-options>] [pbib-options] [bibfile ...]

pbib options:

  -category		set default category for imported references
  -citekey			create the citekey according to the pbib pattern
  -dontstore		just parse input files, do not store the updated bibliography database


bp options:

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

