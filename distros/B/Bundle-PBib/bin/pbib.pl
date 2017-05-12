#! /usr/bin/perl
# $Id: pbib.pl 23 2005-07-17 19:28:02Z tandler $
#
# convert references in rtf, doc or text files
#

=head1 NAME

pbib.pl - process source file to generate list of references

=head1 SYNOPSIS

pbib.pl [options] [source-file ...]

 Options:
   -help            brief help message
   -man             full documentation
   -ref=option      see PBib documentation
   -item=option     see PBib documentation
   -bib=option      see PBib documentation
   -label=option    see PBib documentation
   -final           check for remaining "ToDo" markers and comments

=head1 OPTIONS

=over

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the manual page and exits.

=back

=head1 DESCRIPTION

B<pbib> can convert references in several input file formats 
(such as RTF, DOC, Text, LaTeX) and generate a list of references.

=head1 SEE ALSO

module L<PBib::PBib>

=cut

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib", '$FindBin::Bin/../lib/Biblio/bp/lib';

# for debug
use Data::Dumper;

# used modules
use Getopt::Long;
use Text::ParseWords;
use File::Basename;
#  use File::Spec;
use Pod::Usage;

# used own modules
use Biblio::Biblio;
use PBib::PBib;

my $refStyle = "BookmarkLink";
my $bibStyle = undef;
my $itemStyle = undef; #"IEEE";
my $labelStyle = "Name";


#
#
# get options
#
#

my $in_file;
my $out_file;
my $final_check = 0;

my %refOptions = (
	'class' => 'BookmarkLink',
#	'style' => 'plain',
	'flags' => 'rh',
	'prefix' => 'r',
	'final' => $final_check,
#	'postfix' => 'Reference',
	);
my %itemOptions = (
	'class' => 'ElsevierJSS',
	'debug-undef-entries' => 1,
	'debug-blocks' => 0,
	'includeURL' => 1,
	'includeAnnote' => 0,
	'include-label' => 0,
	'keywordStyle' => 'Abbrev',
	# 'label-separator' => '{tab}',
	# keyword replacements
	# 'page' => 'Seite', 'pages' => 'Seiten',
	);
my %bibOptions = (
#	'class' => 'BookmarkLink',
	);
my %labelOptions = (
	'class' => 'Name',
	# 'forcekey' => 1,
	# 'unique' => 1,
	# 'etal' => 3,
	);
my %pbibOptions = (
	'showresult' => 1,
	);

my @bibtex_infiles;

my ($help, $man, $version, $verbose, $quiet);
my %getopt_config = (
	"ref=s" => \%refOptions,
	"item=s" => \%itemOptions,
	"bib=s" => \%bibOptions,
	"label=s" => \%labelOptions,
	"pbib=s" => \%pbibOptions,

	"final" => \$final_check,
	"bibfile=s" => \@bibtex_infiles,
	'help|?' => \$help,
	'man' => \$man,
	'version' => \$version,
	'verbose+' => \$verbose,
	'quiet' => \$quiet,
	);
GetOptions(%getopt_config) or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-exitstatus => 0, -verbose => 2) if $man;
print STDERR "PBib version $PBib::PBib::VERSION.\n";
exit(0) if $version;

# in case multiple files were given in one arg
@bibtex_infiles = split(/,/,join(',',@bibtex_infiles));
### TODO: actually use @bibtex_infiles ....

# read config

my $config = new PBib::Config(
	'verbose' => $verbose,
	'quiet' => $quiet,
	);


# get all known references

my $bib = new Biblio::Biblio(%{$config->option('biblio')},
	'verbose' => $verbose,
	'quiet' => $quiet,
	) or die "Can't open bibliographic database!\n";

my $refs = $bib->queryPapers();
print "\n";

# process files

my $pbib = new PBib::PBib('refs' => $refs,
		'config' => $config,
		);

pod2usage("$0: No source files given.") if (@ARGV == 0);

foreach my $file (@ARGV) {
	next unless $file;
	#  print "process $file\n";
	$pbib->convertFile($file);
	#  print "\n";
}
